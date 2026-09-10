#!/usr/bin/env python3
"""世界步事务单项消融；所有运行均调用未修改的唯一正式入口。

从任务工作树根目录运行：
  python3 game/tests/experiments/world_step_transaction_ablation.py /tmp/world-step-ablation

先在实际工作树跑正常全量测试，再在每项实验各自的隔离临时副本中移除机制或注入反例，
确认对应测试失败，恢复原字节并再次确认全量通过。源工作树不写入消融。
包含原四项机制消融与按 prepared-result ID 限制一次提交的反例。
原始日志、源码指纹、精确替换、测试清单、计数及工作目录保存在指定证据目录。
"""
from concurrent.futures import ThreadPoolExecutor
from hashlib import sha256
from pathlib import Path
import json
import re
import shutil
import subprocess
import sys
import tempfile

REPOSITORY = Path(__file__).resolve().parents[3]
KERNEL = Path('game/src/rules/world_step_transaction_kernel.gd')
ENTRY = ['bash', 'game/tools/run_headless_tests.sh']
MUTATIONS = {
    'once_only': (
        (
            'static func commit(\n'
            '\tcurrent_state_candidate: RefCounted,\n'
            '\tprepared_result_candidate: RefCounted,\n'
            '\tregistry: RefCounted,\n'
            ') -> WorldStepTransactionResultScript:\n'
            '\treturn _run(current_state_candidate, prepared_result_candidate, registry, true)'
        ),
        (
            'static var _once_only_results: Dictionary[int, bool] = {}\n'
            '\n'
            '\n'
            'static func commit(\n'
            '\tcurrent_state_candidate: RefCounted,\n'
            '\tprepared_result_candidate: RefCounted,\n'
            '\tregistry: RefCounted,\n'
            ') -> WorldStepTransactionResultScript:\n'
            '\tvar result_id: int = prepared_result_candidate.get_instance_id() if prepared_result_candidate != null else -1\n'
            '\tif _once_only_results.has(result_id):\n'
            '\t\treturn _rejected(Reason.INVALID_CANDIDATE)\n'
            '\tvar result := _run(current_state_candidate, prepared_result_candidate, registry, true)\n'
            '\tif result.was_committed():\n'
            '\t\t_once_only_results[result_id] = true\n'
            '\treturn result'
        ),
        'world_step_transaction.duplicate_commit_and_determinism',
    ),
    'prestate': (
        '\tif not current.is_equal_to(candidate.previous_state()):',
        '\tif false:',
        'world_step_transaction.full_prestate_revalidation',
    ),
    'binding': (
        '\t\tif not validate_contact_binding(current, command, lock, candidate.combat_candidate()):',
        '\t\tif false:',
        'world_step_transaction.contact_binding',
    ),
    'step': (
        '\tvar next_step: int = grid.world_step() + 1',
        '\tvar next_step: int = grid.world_step()',
        'world_step_transaction.move_and_wait',
    ),
    'standing': (
        '\t\t\tnext_positions.erase(lock.target_enemy_instance_id())',
        '\t\t\tnext_positions.erase(lock.target_enemy_instance_id())\n\t\t\tnext_positions[PLAYER_ID] = lock.target_enemy_cell()',
        'world_step_transaction.contact_victory_and_next_entry',
    ),
}


def run(root: Path, log_path: Path) -> dict:
    with log_path.open('wb') as output:
        result = subprocess.run(ENTRY, cwd=root, stdout=output, stderr=subprocess.STDOUT)
    data = log_path.read_bytes()
    text = data.decode('utf-8', errors='replace')
    summaries = re.findall(r'^\[TEST\]\[SUMMARY\] total=(\d+) passed=(\d+) failed=(\d+) assertions=(\d+)$', text, re.M)
    counts = dict(zip(('total', 'passed', 'failed', 'assertions'), map(int, summaries[0]))) if len(summaries) == 1 else {}
    return {
        'counts': counts,
        'test_names': sorted(set(re.findall(r'^\[TEST\]\[(?:PASS|FAIL)\] ([^:\s]+)(?::|$)', text, re.M))),
        'cwd': str(root), 'command': ENTRY, 'exit_code': result.returncode,
        'log': str(log_path), 'log_sha256': sha256(data).hexdigest(),
        'summary': re.findall(r'^\[TEST\]\[SUMMARY\].*$', text, re.M),
        'failures': re.findall(r'^\[TEST\]\[FAIL\].*$', text, re.M),
        'has_engine_errors': 'ERROR:' in text,
    }


def passed(result: dict) -> bool:
    counts = result['counts']
    return (
        result['exit_code'] == 0 and not result['has_engine_errors']
        and not result['failures'] and len(result['summary']) == 1
        and bool(counts) and counts['total'] > 0
        and counts['passed'] == counts['total'] and counts['failed'] == 0
        and counts['assertions'] > 0 and len(result['test_names']) == counts['total']
    )


def experiment(name: str, evidence: Path, original: bytes, normal: dict) -> dict:
    old, new, expected_test = MUTATIONS[name]
    assert original.decode().count(old) == 1, f'{name}: source anchor changed'
    record = {'name': name, 'removed': old, 'replacement': new, 'expected_test': expected_test}
    with tempfile.TemporaryDirectory(prefix=f'world-step-{name}-') as directory:
        root = Path(directory)
        shutil.copytree(REPOSITORY / 'game', root / 'game', ignore=shutil.ignore_patterns('.godot'))
        kernel = root / KERNEL
        assert kernel.read_bytes() == original, 'Source changed while copying'
        mutated = original.decode().replace(old, new).encode()
        try:
            kernel.write_bytes(mutated)
            record['mutated_sha256'] = sha256(mutated).hexdigest()
            record['removed_run'] = run(root, evidence / f'{name}-removed.log')
        finally:
            kernel.write_bytes(original)
        assert kernel.read_bytes() == original
        record['restored_sha256'] = sha256(kernel.read_bytes()).hexdigest()
        record['restored_run'] = run(root, evidence / f'{name}-restored.log')
    removed = record['removed_run']
    record['passed'] = (
        removed['exit_code'] != 0 and not removed['has_engine_errors']
        and any(expected_test in failure for failure in removed['failures'])
        and removed['counts'].get('total') == normal['counts']['total']
        and removed['counts'].get('failed', 0) > 0
        and removed['test_names'] == normal['test_names']
        and passed(record['restored_run'])
        and record['restored_run']['test_names'] == normal['test_names']
        and record['restored_run']['counts'] == normal['counts']
    )
    if name == 'once_only':
        record['expected_replay_assertions'] = [
            f'{expected_test}: Replay commit {world}/{action}: committed'
            for world in ('empty', 'shield') for action in ('MOVE', 'WAIT')
        ]
        record['passed'] = record['passed'] and all(
            any(marker in failure for failure in removed['failures'])
            for marker in record['expected_replay_assertions']
        )
    (evidence / f'{name}.json').write_text(json.dumps(record, ensure_ascii=False, indent=2) + '\n')
    print(f"{name}: {'PASS' if record['passed'] else 'FAIL'}", flush=True)
    return record


def main() -> int:
    if Path.cwd().resolve() != REPOSITORY:
        raise SystemExit('Run from the actual task worktree root.')
    if len(sys.argv) != 2:
        raise SystemExit('Expected a new evidence directory path.')
    evidence = Path(sys.argv[1]).resolve()
    evidence.mkdir(parents=True, exist_ok=False)
    original = (REPOSITORY / KERNEL).read_bytes()
    normal = run(REPOSITORY, evidence / 'normal.log')
    report = {'source_root': str(REPOSITORY), 'source_sha256': sha256(original).hexdigest(), 'normal': normal}
    if not passed(normal):
        (evidence / 'report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
        return 1
    print(f'normal: PASS; starting {len(MUTATIONS)} isolated experiments', flush=True)
    with ThreadPoolExecutor(max_workers=len(MUTATIONS)) as executor:
        futures = [executor.submit(experiment, name, evidence, original, normal) for name in MUTATIONS]
        report['experiments'] = [future.result() for future in futures]
    report['source_unchanged'] = (REPOSITORY / KERNEL).read_bytes() == original
    report['passed'] = report['source_unchanged'] and all(item['passed'] for item in report['experiments'])
    (evidence / 'report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
