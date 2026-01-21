---------------- MODULE BatteryHardwareComponent_forCheck_v3 ----------------
EXTENDS Integers, Sequences, Naturals

CONSTANTS 
    MaxBattery,      \* バッテリーの最大容量
    ChargerPos,      \* 充電器の位置の集合 {<<x, y>>, ...}
    InitialPlan        \* 実行すべきプラン

(* 座標は <<x, y>> のタプルで表現します。
   プランは座標のシーケンスです。
*)

(* 演算子の定義 *)
Abs(x) == IF x < 0 THEN -x ELSE x
ManhattanDist(p1, p2) == Abs(p1[1] - p2[1]) + Abs(p1[2] - p2[2])

(* 最寄りの充電器までの距離を計算するヘルパー *)
DistToNearestCharger(pos) == 
    CHOOSE d \in {ManhattanDist(pos, c) : c \in ChargerPos} : 
        \A other \in {ManhattanDist(pos, c2) : c2 \in ChargerPos} : d <= other

(* --algorithm RoverBatteryHardware
   
   variables
     (* 物理的なバッテリー残量 *)
     actualBattery = MaxBattery;
     
     (* システムに報告されるバッテリー残量 (BM2) *)
     reportedBattery = MaxBattery; 
     
     (* 現在位置 *)
     currentPosition = <<0, 0>>;
     
     (* 現在の目標地点 (GRAから与えられると仮定) *)
     currentGoal = <<5, 5>>; 
     
     (* 実行すべきプラン (座標の列) *)
     executionPlan = InitialPlan; 
     
     (* 状態フラグ *)
     rechargeFlag = FALSE;    (* HI1 *)
     atGoal = FALSE;          (* HI3 *)
     solarPanelsOpen = FALSE; (* HI6, HI7 *)
     isCharging = FALSE;      (* 内部状態 *)

   define
     (* BM2: 劣化を考慮し、計測値より5%少なく報告する  *)
     SafeBatteryLevel == 
        (actualBattery * 95) \div 100 
        
     (* HI1のための必要バッテリー計算 *)
     (* ゴールまでの距離 + ゴールから最寄りの充電器までの距離 *)
     RequiredBattery == 
        ManhattanDist(currentPosition, currentGoal) + DistToNearestCharger(currentGoal)
        
     (* ▼▼▼ 追加: SL1 (System Level Requirement 1) ▼▼▼ *)
     (* "The rover shall never run out of battery."  *)
     (* バッテリーが0より大きい状態を維持しなければならない *)
     SL1 == actualBattery > 0
   end define;

   (* バッテリー監視プロセス (BatteryMonitor) *)
   fair process Monitor = "BatteryMonitor"
   begin
     MonitorLoop:
       while TRUE do
         (* BM1: バッテリーレベルを監視する  *)
         (* BM2: 値を更新する  *)
         reportedBattery := SafeBatteryLevel;
         
         (* HI1: ゴール到達後に充電器へ行けるかチェックし、不足ならフラグを立てる  *)
         if reportedBattery < RequiredBattery then
            rechargeFlag := TRUE;
         else
            rechargeFlag := FALSE;
         end if;
       end while;
   end process;

   (* ▼▼▼ 追加: 環境プロセス (Sunlight/Physics) ▼▼▼ *)
   (* パネルが開いている間、バッテリーを徐々に回復させる *)
   fair process Environment = "Sunlight"
   begin
     SunLoop:
       while TRUE do
         if solarPanelsOpen /\ actualBattery < MaxBattery then
            (* 物理現象: バッテリーが回復する *)
            actualBattery := actualBattery + 1;
         end if;
       end while;
   end process;
   (* ▲▲▲ 追加ここまで ▲▲▲ *)

   (* ハードウェア制御プロセス *)
   fair process Controller = "HardwareController"
   variables nextWaypoint;
   begin
     ControlLoop:
       while TRUE do
         (* 充電ロジック *)
         if currentPosition \in ChargerPos /\ actualBattery < MaxBattery then
            (* HI6: ソーラーパネルを開く *)
            OpenPanels:
                solarPanelsOpen := TRUE;
                isCharging := TRUE;
            
            (* ステップ2: 完了待ちと終了処理 *)
            (* 環境プロセスが actualBattery を増やすのをここで待つ *)
            WaitForCharge:
                await actualBattery = MaxBattery; 
                isCharging := FALSE;
            
            (* HI7: パネルを閉じる *)
            ClosePanels:
                solarPanelsOpen := FALSE;
         
         else
            CheckMove:
            if Len(executionPlan) > 0 /\ ~isCharging then
                (* HI4: 移動コマンド *)
                MoveStep:
                    nextWaypoint := Head(executionPlan);
                    executionPlan := Tail(executionPlan);
                    
                    (* HI5: 位置更新 *)
                    currentPosition := nextWaypoint;
                    
                    if actualBattery > 0 then
                        actualBattery := actualBattery - 1;
                    end if;
                    
                    if currentPosition = currentGoal then
                        atGoal := TRUE;
                    else
                        atGoal := FALSE;
                    end if;
            end if; 
         end if;
         
       end while;
   end process;
end algorithm; *)
\* BEGIN TRANSLATION
CONSTANT defaultInitValue
VARIABLES actualBattery, reportedBattery, currentPosition, currentGoal, 
          executionPlan, rechargeFlag, atGoal, solarPanelsOpen, isCharging, 
          pc

(* define statement *)
SafeBatteryLevel ==
   (actualBattery * 95) \div 100



RequiredBattery ==
   ManhattanDist(currentPosition, currentGoal) + DistToNearestCharger(currentGoal)




SL1 == actualBattery > 0

VARIABLE nextWaypoint

vars == << actualBattery, reportedBattery, currentPosition, currentGoal, 
           executionPlan, rechargeFlag, atGoal, solarPanelsOpen, isCharging, 
           pc, nextWaypoint >>

ProcSet == {"BatteryMonitor"} \cup {"Sunlight"} \cup {"HardwareController"}

Init == (* Global variables *)
        /\ actualBattery = MaxBattery
        /\ reportedBattery = MaxBattery
        /\ currentPosition = <<0, 0>>
        /\ currentGoal = <<5, 5>>
        /\ executionPlan = InitialPlan
        /\ rechargeFlag = FALSE
        /\ atGoal = FALSE
        /\ solarPanelsOpen = FALSE
        /\ isCharging = FALSE
        (* Process Controller *)
        /\ nextWaypoint = defaultInitValue
        /\ pc = [self \in ProcSet |-> CASE self = "BatteryMonitor" -> "MonitorLoop"
                                        [] self = "Sunlight" -> "SunLoop"
                                        [] self = "HardwareController" -> "ControlLoop"]

MonitorLoop == /\ pc["BatteryMonitor"] = "MonitorLoop"
               /\ reportedBattery' = SafeBatteryLevel
               /\ IF reportedBattery' < RequiredBattery
                     THEN /\ rechargeFlag' = TRUE
                     ELSE /\ rechargeFlag' = FALSE
               /\ pc' = [pc EXCEPT !["BatteryMonitor"] = "MonitorLoop"]
               /\ UNCHANGED << actualBattery, currentPosition, currentGoal, 
                               executionPlan, atGoal, solarPanelsOpen, 
                               isCharging, nextWaypoint >>

Monitor == MonitorLoop

SunLoop == /\ pc["Sunlight"] = "SunLoop"
           /\ IF solarPanelsOpen /\ actualBattery < MaxBattery
                 THEN /\ actualBattery' = actualBattery + 1
                 ELSE /\ TRUE
                      /\ UNCHANGED actualBattery
           /\ pc' = [pc EXCEPT !["Sunlight"] = "SunLoop"]
           /\ UNCHANGED << reportedBattery, currentPosition, currentGoal, 
                           executionPlan, rechargeFlag, atGoal, 
                           solarPanelsOpen, isCharging, nextWaypoint >>

Environment == SunLoop

ControlLoop == /\ pc["HardwareController"] = "ControlLoop"
               /\ IF currentPosition \in ChargerPos /\ actualBattery < MaxBattery
                     THEN /\ pc' = [pc EXCEPT !["HardwareController"] = "OpenPanels"]
                     ELSE /\ pc' = [pc EXCEPT !["HardwareController"] = "CheckMove"]
               /\ UNCHANGED << actualBattery, reportedBattery, currentPosition, 
                               currentGoal, executionPlan, rechargeFlag, 
                               atGoal, solarPanelsOpen, isCharging, 
                               nextWaypoint >>

OpenPanels == /\ pc["HardwareController"] = "OpenPanels"
              /\ solarPanelsOpen' = TRUE
              /\ isCharging' = TRUE
              /\ pc' = [pc EXCEPT !["HardwareController"] = "WaitForCharge"]
              /\ UNCHANGED << actualBattery, reportedBattery, currentPosition, 
                              currentGoal, executionPlan, rechargeFlag, atGoal, 
                              nextWaypoint >>

WaitForCharge == /\ pc["HardwareController"] = "WaitForCharge"
                 /\ actualBattery = MaxBattery
                 /\ isCharging' = FALSE
                 /\ pc' = [pc EXCEPT !["HardwareController"] = "ClosePanels"]
                 /\ UNCHANGED << actualBattery, reportedBattery, 
                                 currentPosition, currentGoal, executionPlan, 
                                 rechargeFlag, atGoal, solarPanelsOpen, 
                                 nextWaypoint >>

ClosePanels == /\ pc["HardwareController"] = "ClosePanels"
               /\ solarPanelsOpen' = FALSE
               /\ pc' = [pc EXCEPT !["HardwareController"] = "ControlLoop"]
               /\ UNCHANGED << actualBattery, reportedBattery, currentPosition, 
                               currentGoal, executionPlan, rechargeFlag, 
                               atGoal, isCharging, nextWaypoint >>

CheckMove == /\ pc["HardwareController"] = "CheckMove"
             /\ IF Len(executionPlan) > 0 /\ ~isCharging
                   THEN /\ pc' = [pc EXCEPT !["HardwareController"] = "MoveStep"]
                   ELSE /\ pc' = [pc EXCEPT !["HardwareController"] = "ControlLoop"]
             /\ UNCHANGED << actualBattery, reportedBattery, currentPosition, 
                             currentGoal, executionPlan, rechargeFlag, atGoal, 
                             solarPanelsOpen, isCharging, nextWaypoint >>

MoveStep == /\ pc["HardwareController"] = "MoveStep"
            /\ nextWaypoint' = Head(executionPlan)
            /\ executionPlan' = Tail(executionPlan)
            /\ currentPosition' = nextWaypoint'
            /\ IF actualBattery > 0
                  THEN /\ actualBattery' = actualBattery - 1
                  ELSE /\ TRUE
                       /\ UNCHANGED actualBattery
            /\ IF currentPosition' = currentGoal
                  THEN /\ atGoal' = TRUE
                  ELSE /\ atGoal' = FALSE
            /\ pc' = [pc EXCEPT !["HardwareController"] = "ControlLoop"]
            /\ UNCHANGED << reportedBattery, currentGoal, rechargeFlag, 
                            solarPanelsOpen, isCharging >>

Controller == ControlLoop \/ OpenPanels \/ WaitForCharge \/ ClosePanels
                 \/ CheckMove \/ MoveStep

Next == Monitor \/ Environment \/ Controller

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(Monitor)
        /\ WF_vars(Environment)
        /\ WF_vars(Controller)

\* END TRANSLATION

=============================================================================
