# assembly_knowledge

## TODO

- Step1(furniture_info)와 Step3(assembly_sequences) 포맷은 구체화 되었으나, Step2(part_info)는 미완성
- 조립설명서 내용 파악 알고리즘을 고려하여 Step2(part_info) 형식을 검토 및 수정 할 필요 있음
- GIST 내부 논의 후 Assembly Sequence Generator & Validator 구성 방법 및 Score 부여 방법 구체화 예정
- 모델 파일 및 모델 이름 통일 필요

## Definitions

| 국문명    | 영문명            | 설명                                        |
|-----------|-------------------|---------------------------------------------|
| 조립 설명서 | Assembly Instruction | |
| 조립 부품 | Assembly Part     | 가구 부품, 체결 부품을 포함한 조립에 사용되는 모든 부품   |
| 가구 부품 | Furniture Part    | 큰 부품 (의자 옆면, 앞면)                   |
| 연결 부품 | Connectors        | 작은 부품 (볼트, 너트, 브라켓 등)                   |
| 조립 위치 | Assembly Point    | 각 부품의 원점으로부터 조립 위치의 T, R        |
| 조립 행동 | Assembly Action   | 끼우기, 돌려 넣기 등 (설명서 기준)             |
| 조립 기술 | Assembly Skill    | 이중 펙인홀, 단일 펙인홀 등 (로봇 기준)        |
| 조립     | Assembly          | 단위 조립 1개는 부품 A + 부품 B를 의미           |
| 조립 대상 | Assembly Target | 특정 부품을 기준으로의 상대 부품과의 결합 정보 |
| 조립 순서 | Assembly Sequence | 조립1 (부품 A + 부품 B) + 조립2 (부품 C + 부품 D) + ... |
| 설명서 단계 | Instruction Step | 설명서에 지시된 조립 단계 |

---

## Step 1

- 대회 당일 부품별 CAD 파일 수령 (model_file)
- CAD 파일명으로부터 조립 부품별 연결 부품의 수량(quantity) 및 종류(class_id) 파악
- 조립설명서 내 글자 인식 -> 가구 부품의 수량(quantity) 및 연결부품 ID(connector_id) 파악

### furniture_info

- 특정 가구(ex. STEFAN)를 이루는 모든 조립부품에 대한 기본 정보
- CAD파일-class_id 단위로 조립부품을 구분

#### stefan.yaml

```yaml
ikea_stefan_side_left:
    class_id: 1
    type: furniture_part
    quantity: 1
    model_file: ikea_stefan_side_left.stl

ikea_stefan_long:
    class_id: 2
    type: furniture_part
    quantity: 1
    model_file: ikea_stefan_long.stl

ikea_l_bracket:
    class_id: 3
    type: connector
    connector_id: 122620 # 조립 설명서 상의 체결 부품 id
    quantity: 4 # instance 개수
    model_file: ikea_l_bracket.stl
```

---

## Step 2

- Furniture Info -> instance_id 할당
- CAD 파일 분석 -> sub-axis 추출 및 Hole 크기 대조 -> 물리적으로 가능한 조립 위치 후보군 (assembly_points) 추출
- 조립설명서 내 객체 인식 -> 설명서 단계 (instruction_step) 및 단계별 조립 부품-조립 행동(assembly_target, assembly_action) 추출

### part_info

- 조립 부품(instance_id)별 조립 정보
- 조립 단계(assembly sequence) 생성 시 Node 및 Edge 정보로 활용

#### part_info.yaml

```yaml
ikea_stefan_side_left_1: # instance_id, 추후 디버깅의 편리를 위해 type_i
    type: ikea_stefan_side_left # stefan.yaml 에서 정보를 가져옴

    assembly_points: # 이 부품의 결합 가능한 모든 위치
        - id: 1
            pose: [[x, y, z], [x, y, z, w]] # point, orientation (quaternion)
            is_used: False # 결합 부위의 사용 여부.
        - id: 2
            pose: [[x, y, z], [x, y, z, w]] # point, orientation (quaternion)
            is_used: False

    assembly_targets: # 이 부품을 기준으로, 물리적으로 가능한 모든 상대 부품과의 결합 방법
        - id: 1 #
            assembly_point_ids: [1] # 조립시 사용되는 이 부품의 assembly_point_id, multi peg-in-hole일 경우 2개 이상.
            target_part_class_id: 2 # 조립시 사용되는 상대 부품의 ID
            target_part_type: ikea_stefan_long
            target_part_assembly_point_ids: [2] # 조립시 사용되는 상대 부품의 assembly_point_id
            instruction_step: 1 # 설명서에 기재된 순서, 기재되지 않았을 경우 None
            score: 10
            # ex. 설명서에서 지시한 내용(A와 B가 결합한다.) + 물리적으로 가능 = 10
            # 설명서에는 없으나 물리적으로 가능함 = 1
            assembly_action: "끼워넣기" # 설명서 기준 조립 방법
        - id: 2
            ...
```

---

## Step 3

- 가상 시뮬레이션으로부터 동일 Score 간의 우선 순위를 결정 -> 세부 Score 할당
- Part Info로부터 가능한 Assembly Sequences를 탐색
- Score가 높은 순서대로 `sequence_id`를 부여
- 조립 부품과 조립 행동을 고려하여 로봇이 수행할 `조립 스킬(Assembly Skill)`을 결정

### assembly_sequences

- 알고리즘이 Part Info를 기반으로 생성해낸 조립 순서. Score가 높은 순서대로 정렬

#### assembly_sequence_1.yaml

``` yaml
sequence_id: 1 # id는 스코어 높은 순서대로
total_score: 152
assemblies:
  - assembly_id: 1 # 조립 단계 순서별로 부여. 단위 조립은 부품 A + 부품 B
    assembly_skill: "single peg-in-hole"
    score: 10 # 해당 조립 단계의 점수
    assembly_part_pairs: [ikea_stefan_long_1, ikea_l_bracket_1] # [[부품 A의 instance id], [부품 B의 instance id]]
    # [[부품 A의 assembly_point_id], [부품 B의 assembly_point_id]]
    # multi peg-in-hole인 경우 여러개. e.g. : [[2, 3], [1,2]]
    assembly_point_pairs: [[5], [1]]
    assembly_status:
        ikea_stefan_long_1: {}
        ikea_stefan_short_1: {}
        ikea_stefan_middle_1: {}
        ikea_stefan_bottom_1: {}
        ikea_stefan_side_left_1: {}
        ikea_stefan_side_right_1: {}
        ikea_l_bracket_1: {}
        ikea_l_bracket_2: {}
        ikea_l_bracket_3: {}
        ikea_l_bracket_4: {}
        ikea_wood_pin_1: {}
        ikea_wood_pin_2: {}
        ikea_wood_pin_3: {}
        ikea_wood_pin_4: {}
        ikea_wood_pin_5: {}
        ikea_wood_pin_6: {}
        ikea_wood_pin_7: {}
        ikea_wood_pin_8: {}
        ikea_wood_pin_9: {}
        ikea_wood_pin_10: {}
        ikea_wood_pin_11: {}
        ikea_wood_pin_12: {}
        ikea_wood_pin_13: {}
        ikea_wood_pin_14: {}
    assembly_desired_status:
        ikea_stefan_long_1:
            ikea_l_bracket_1: {}
        ikea_stefan_short_1: {}
        ikea_stefan_middle_1: {}
        ikea_stefan_bottom_1: {}
        ikea_stefan_side_left_1: {}
        ikea_stefan_side_right_1: {}
        ikea_l_bracket_2: {}
        ikea_l_bracket_3: {}
        ikea_l_bracket_4: {}
        ikea_wood_pin_1: {}
        ikea_wood_pin_2: {}
        ikea_wood_pin_3: {}
        ikea_wood_pin_4: {}
        ikea_wood_pin_5: {}
        ikea_wood_pin_6: {}
        ikea_wood_pin_7: {}
        ikea_wood_pin_8: {}
        ikea_wood_pin_9: {}
        ikea_wood_pin_10: {}
        ikea_wood_pin_11: {}
        ikea_wood_pin_12: {}
        ikea_wood_pin_13: {}
        ikea_wood_pin_14: {}

  - assembly_id: 22
    assembly_skill: "dual peg-in-hole"
    score: 10
    assembly_part_pairs: [ikea_stefan_side_left_1, ikea_stefan_long_1]
    assembly_point_pairs: [[1, 2], [1, 2]]
    assembly_status:
        ikea_stefan_long_1:
            ikea_wood_pin_1: {} # connector는 부품의 child로 하여 명시적으로 조립된 것을 표기
            ikea_wood_pin_2: {}
            ikea_wood_pin_3: {}
            ikea_wood_pin_4: {}
            ikea_l_bracket_1: {}
            ikea_l_bracket_2: {}
        ikea_stefan_short_1: {}
        ikea_stefan_middle_1: {}
        ikea_stefan_bottom_1: {}
        ikea_stefan_side_left_1: {}
        ikea_stefan_side_right_1: {}
        ikea_l_bracket_3: {}
        ikea_l_bracket_4: {}
        ikea_wood_pin_5: {}
        ikea_wood_pin_6: {}
        ikea_wood_pin_7: {}
        ikea_wood_pin_8: {}
        ikea_wood_pin_9: {}
        ikea_wood_pin_10: {}
        ikea_wood_pin_11: {}
        ikea_wood_pin_12: {}
        ikea_wood_pin_13: {}
        ikea_wood_pin_14: {}
    assembly_desired_status:
        ikea_stefan_short_1: {}
        ikea_stefan_middle_1: {}
        ikea_stefan_bottom_1: {}
        ikea_stefan_side_left_1:
            ikea_stefan_long_1:
                ikea_wood_pin_1: {} # connector는 부품의 child로 하여 명시적으로 조립된 것을 표기
                ikea_wood_pin_2: {}
                ikea_wood_pin_3: {}
                ikea_wood_pin_4: {}
                ikea_l_bracket_1: {}
                ikea_l_bracket_2: {}
        ikea_stefan_side_right_1: {}
        ikea_l_bracket_3: {}
        ikea_l_bracket_4: {}
        ikea_wood_pin_5: {}
        ikea_wood_pin_6: {}
        ikea_wood_pin_7: {}
        ikea_wood_pin_8: {}
        ikea_wood_pin_9: {}
        ikea_wood_pin_10: {}
        ikea_wood_pin_11: {}
        ikea_wood_pin_12: {}
        ikea_wood_pin_13: {}
        ikea_wood_pin_14: {}

  - assembly_id: 33
    assembly_skill: "placement" # 끼워넣기?
    score: 10
    assembly_part_pairs: [ikea_stefan_side_left_1, ikea_stefan_bottom_1]
    assembly_point_pairs: [50, 1] # 이 부분 어떻게 할 지 논의 필요
    assembly_status:
        ikea_stefan_side_left_1:
            ikea_stefan_long_1:
                ikea_stefan_side_right_1: {} # 여러 부품과 동시에 결합되는 것은 하나에만 표기?
                ikea_wood_pin_1: {} # connector는 부품의 child로 하여 명시적으로 조립된 것을 표기
                ikea_wood_pin_2: {}
                ikea_wood_pin_3: {}
                ikea_wood_pin_4: {}
                ikea_l_bracket_1: {}
                ikea_l_bracket_2: {}
            ikea_stefan_short_1:
                ikea_wood_pin_5: {}
                ikea_wood_pin_6: {}
                ikea_wood_pin_7: {}
                ikea_wood_pin_8: {}
                ikea_l_bracket_3: {}
                ikea_l_bracket_4: {}
            ikea_stefan_middle_1:
                ikea_wood_pin_9: {}
                ikea_wood_pin_10: {}
                ikea_wood_pin_11: {}
                ikea_wood_pin_12: {}
                ikea_wood_pin_13: {}
                ikea_wood_pin_14: {}
        ikea_stefan_bottom_1: {}
    assembly_desired_status:
        ikea_stefan_side_left_1:
            ikea_stefan_long_1:
                ikea_stefan_side_right_1: {} # 여러 부품과 동시에 결합되는 것은 하나에만 표기?
                ikea_wood_pin_1: {} # connector는 부품의 child로 하여 명시적으로 조립된 것을 표기
                ikea_wood_pin_2: {}
                ikea_wood_pin_3: {}
                ikea_wood_pin_4: {}
                ikea_l_bracket_1: {}
                ikea_l_bracket_2: {}
            ikea_stefan_short_1:
                ikea_wood_pin_5: {}
                ikea_wood_pin_6: {}
                ikea_wood_pin_7: {}
                ikea_wood_pin_8: {}
                ikea_l_bracket_3: {}
                ikea_l_bracket_4: {}
            ikea_stefan_middle_1:
                ikea_wood_pin_9: {}
                ikea_wood_pin_10: {}
                ikea_wood_pin_11: {}
                ikea_wood_pin_12: {}
                ikea_wood_pin_13: {}
                ikea_wood_pin_14: {}
            ikea_stefan_bottom_1: {}
...
```
