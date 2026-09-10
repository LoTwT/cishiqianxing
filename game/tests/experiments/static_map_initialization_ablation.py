#!/usr/bin/env python3
"""静态地图单项消融；正常、反例与恢复均运行未修改的唯一正式测试入口。

用法：python3 game/tests/experiments/static_map_initialization_ablation.py /tmp/static-map-ablation
证据目录必须尚不存在。只修改隔离副本，保存精确变体、全源码指纹及原始日志。
引用、占格和未支持内容还受完整内容封印保护；这三项验证结构化诊断的独立作用，
不声称移除单项校验即可绕过全部等价防线。
"""
from concurrent.futures import ThreadPoolExecutor
from hashlib import sha256
from pathlib import Path
import json
import shutil
import sys
import tempfile

from world_step_transaction_ablation import run, passed

REPOSITORY = Path(__file__).resolve().parents[3]
VALIDATOR = Path('game/src/content/static_map_validator.gd')
MUTATIONS = {
    'reference': (
        VALIDATOR,
        '\t\t\t\t_issue(issues, ContentValidationIssueScript.MAP_REFERENCE_INVALID, definition.map_id, field, "Enemy placement references an unknown central profile.")',
        '\t\t\t\tpass',
        'static_maps.rejects_references_and_chapters',
        'Removing the unknown-profile diagnostic still leaves the full manifest seal as an equivalent rejection defense.',
    ),
    'occupancy': (
        VALIDATOR,
        '\t\tfor error: String in grid.validation_errors():',
        '\t\tfor error: String in grid.validation_errors().slice(0, 0):',
        'static_maps.rejects_geometry_and_occupancy',
        'Removing grid diagnostics still leaves the full content seal and runtime grid validation; the specific structural contract must nevertheless fail.',
    ),
    'unsupported': (
        VALIDATOR,
        '\t\tif not (definition.terrain_effect_ids_snapshot().is_empty() and definition.dynamic_behavior_ids_snapshot().is_empty() and definition.other_entity_ids_snapshot().is_empty()):',
        '\t\tif false:',
        'static_maps.rejects_unsupported_content',
        'The content seal and initializer also reject these sources; this variant removes the central unsupported-content diagnostic only.',
    ),
    'fingerprint': (
        Path('game/src/content/content_contract_fingerprint.gd'),
        '\t\tpayload += "p" + _encode_cell(definition.player_spawn_cell)',
        '\t\tpayload += "p" + _encode_cell(Vector3i.ZERO)',
        'static_maps.fingerprints_every_map_field',
        'Canonical spawn remains identical, but a legal shifted spawn is no longer sealed. The independent field mutation must expose the omission.',
    ),
    'snapshot': (
        Path('game/src/content/static_map_query_result.gd'),
        '\treturn StaticMapDefinitionScript.snapshot(_definition) if succeeded() else null',
        '\treturn _definition if succeeded() else null',
        'static_maps.isolates_snapshots_and_resource_cache',
        'Two reads share a query-owned Resource. Mutating one read must be detected by the second-read isolation assertions.',
    ),
    'source_loading': (
        Path('game/src/content/definitions/static_map_definition_resource.gd'),
        '\tif not _is_source_id_array(value):\n\t\t_invalid_source_fields |= bit\n\t\treturn true',
        '\tif not _is_source_id_array(value):\n\t\treturn true',
        'static_map_sources.rejects_loaded_scalar_declarations',
        'Discarding the malformed native Resource input without retaining its invalid status recreates the empty-default bug; later guards see apparently valid empty declarations.',
    ),
    'source_validity_seal': (
        Path('game/src/content/content_contract_fingerprint.gd'),
        '\t\tif not definition.source_declarations_are_valid():\n\t\t\treturn ""',
        '\t\tif false:\n\t\t\treturn ""',
        'static_map_sources.seals_declaration_validity',
        'Omitting declaration validity from seal verification lets a malformed redeclaration retain the original empty-value fingerprint; initializer validation is an additional defense, not a replacement for registry integrity.',
    ),
}


def source_hashes(root: Path) -> dict:
    return {
        str(path.relative_to(root)): sha256(path.read_bytes()).hexdigest()
        for path in sorted((root / 'game').rglob('*'))
        if path.is_file() and '.godot' not in path.parts and '__pycache__' not in path.parts
    }


def experiment(name: str, evidence: Path, original_hashes: dict, normal: dict) -> dict:
    path, old, new, expected_test, interpretation = MUTATIONS[name]
    original = (REPOSITORY / path).read_bytes()
    assert original.decode().count(old) == 1, f'{name}: source anchor changed'
    record = {'name': name, 'path': str(path), 'removed': old, 'replacement': new,
              'expected_test': expected_test, 'interpretation': interpretation}
    with tempfile.TemporaryDirectory(prefix=f'static-map-{name}-') as directory:
        root = Path(directory)
        shutil.copytree(REPOSITORY / 'game', root / 'game', ignore=shutil.ignore_patterns('.godot', '__pycache__'))
        assert source_hashes(root) == original_hashes, 'Source changed while copying'
        target = root / path
        try:
            target.write_bytes(original.decode().replace(old, new).encode())
            record['mutated_sources'] = source_hashes(root)
            record['removed_run'] = run(root, evidence / f'{name}-removed.log')
        finally:
            target.write_bytes(original)
        record['restored_sources'] = source_hashes(root)
        assert record['restored_sources'] == original_hashes
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
    originals = source_hashes(REPOSITORY)
    normal = run(REPOSITORY, evidence / 'normal.log')
    report = {'source_root': str(REPOSITORY), 'source_hashes': originals, 'normal': normal}
    if not passed(normal):
        (evidence / 'report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
        return 1
    print(f'normal: PASS; starting {len(MUTATIONS)} isolated experiments', flush=True)
    with ThreadPoolExecutor(max_workers=len(MUTATIONS)) as executor:
        futures = [executor.submit(experiment, name, evidence, originals, normal) for name in MUTATIONS]
        report['experiments'] = [future.result() for future in futures]
    report['source_unchanged'] = source_hashes(REPOSITORY) == originals
    report['passed'] = report['source_unchanged'] and all(item['passed'] for item in report['experiments'])
    (evidence / 'report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
