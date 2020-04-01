# assembly_knowledge

## TODO

- Step1(furniture_info)와 Step3(assembly_sequences) 포맷은 구체화 되었으나, Step2(part_info)는 미완성
- 조립설명서 내용 파악 알고리즘을 고려하여 Step2(part_info) 형식을 검토 및 수정 할 필요 있음
- GIST 내부 논의 후 Assembly Sequence Generator & Validator 구성 방법 및 Score 부여 방법 구체화 예정

## Definitions

| 국문명    | 영문명            | 설명                                        |
|-----------|-------------------|---------------------------------------------|
| 조립 설명서 | Assembly Instruction | |
| 조립 부품 | Assembly Part     | 가구 부품, 체결 부품을 포함한 조립에 사용되는 모든 부품   |
| 가구 부품 | Furniture Part    | 큰 부품 (의자 옆면, 앞면)                   |
| 연결 부품 | Connectors        | 작은 부품 (볼트, 너트 등)                   |
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

    chair_bracket:
        class_id: 1 
        type: connector
        connector_id: 122620 # 조립 설명서 상의 체결 부품 id
        quantity: 4 # instance 개수
        model_file: chair_braket(4ea).STEP

    chair_part1:
        class_id: 2
        type: furniture_part
        quantity: 1
        model_file: chair_part1.STEP

---
## Step 2

- Furniture Info -> instance_id 할당
- CAD 파일 분석 -> sub-axis 추출 및 Hole 크기 대조 -> 물리적으로 가능한 조립 위치 후보군 (assembly_points) 추출
- 조립설명서 내 객체 인식 -> 설명서 단계 (instruction_step) 및 단계별 조립 부품-조립 행동(assembly_target, assembly_action) 추출


### part_info

- 조립 부품(instance_id)별 조립 정보
- 조립 단계(assembly sequence) 생성 시 Node 및 Edge 정보로 활용

#### stefan_side_left_1.yaml

    class_id: 1
    instance_id: 1
    type: furniture_part
    model_file: stefan_side_left.stl
    assembly_points: # 이 부품의 결합 가능한 모든 위치
        - assembly_point_id: 1
          rotation: [q1, q2, q3, q4]
          translation: [x, y, z]
          is_used: False # 결합 부위의 사용 여부.

        - assembly_point_id: 2
          rotation: [q1', q2', q3', q4']
          translation: [x', y', z']
          is_used: False

    assembly targets: # 이 부품을 기준으로, 물리적으로 가능한 모든 상대 부품과의 결합 방법
        - assembly_target_id: 1 #
          assembly_point_ids: [1] # 조립시 사용되는 이 부품의 assembly_point_id, multi peg-in-hole일 경우 2개 이상.
          target_part_class_id: 2 # 조립시 사용되는 상대 부품의 ID
          target_part_assembly_point_ids: [2] # 조립시 사용되는 상대 부품의 assembly_point_id
          instruction step: 1 # 설명서에 기재된 순서, 기재되지 않았을 경우 None
          score: 10 # ex. 설명서에서 지시한 내용(A와 B가 결합한다.) + 물리적으로 가능 = 10 / 설명서에는 없으나 물리적으로 가능함 = 1
          assembly_action: "끼워넣기" # 설명서 기준 조립 방법
        - assembly_target_id: 2
        - ...

---
## Step 3

- 가상 시뮬레이션으로부터 동일 Score 간의 우선 순위를 결정 -> 세부 Score 할당
- Part Info로부터 가능한 Assembly Sequences를 탐색
- Score가 높은 순서대로 **sequence_id**를 부여
- 조립 부품과 조립 행동을 고려하여 로봇이 수행할 **조립 스킬(assembly skill)**을 결정

### aseembly_sequences

- 알고리즘이 Part Info를 기반으로 생성해낸 조립 순서. Score가 높은 순서대로 정렬

#### assembly_sequence_1.yaml
    sequence_id: 1 # id는 스코어 높은 순서대로
    total score: 152
    Assemblies:
        - assembly_id: 1 # 조립 단계 순서별로 부여. 단위 조립은 부품 A + 부품 B
          assembly_skill: "single peg-in-hole"
          score: 10 # 해당 조립 단계의 점수
          assembly_part_pairs: [[1], [3]] # 부품 A의 instance id - 부품 B의 instance id
          assembly_point_pairs: [[2], [4]] # (부품 A의 assembly_point_id - 부품 B의 assembly_point_id), multi peg-in-hole인 경우 여러개

        - assembly_id: 2
          score: 10 
          assembly_skill: "dual peg-in-hole"
          assembly_part_pairs: [[1, 1], [2, 3]] 
          assembly_point_pairs: [[1, 2], [1, 1]]

        - assembly_id: 10
          ...