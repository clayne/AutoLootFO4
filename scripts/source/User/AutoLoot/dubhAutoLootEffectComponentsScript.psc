ScriptName AutoLoot:dubhAutoLootEffectComponentsScript Extends ActiveMagicEffect

Import AutoLoot:dubhAutoLootUtilityScript


; -----------------------------------------------------------------------------
; EVENTS
; -----------------------------------------------------------------------------

Event OnEffectStart(Actor akTarget, Actor akCaster)
  StartTimer(Delay.GetValue() as Int, TimerID)
EndEvent

Event OnTimer(Int aiTimerID)
  If PlayerRef.HasPerk(ActivePerk)
    If IsPlayerControlled()
      BuildAndProcessReferences(Filter)
    EndIf

    StartTimer(Delay.GetValue() as Int, TimerID)
  EndIf
EndEvent

; -----------------------------------------------------------------------------
; FUNCTIONS
; -----------------------------------------------------------------------------

Function _Log(String asTextToPrint, Int aiSeverity = 0) DebugOnly
  Debug.OpenUserLog("AutoLoot")
  Debug.TraceUser("AutoLoot", "dubhAutoLootEffectComponentsScript> " + asTextToPrint, aiSeverity)
EndFunction

Function LogInfo(String asTextToPrint) DebugOnly
  _Log("[INFO] " + asTextToPrint, 0)
EndFunction

Function LogWarning(String asTextToPrint) DebugOnly
  _Log("[WARN] " + asTextToPrint, 1)
EndFunction

Function LogError(String asTextToPrint) DebugOnly
  _Log("[ERRO] " + asTextToPrint, 2)
EndFunction

Bool Function ItemCanBeProcessed(ObjectReference akItem)
  If !IsObjectInteractable(akItem)
    Return False
  EndIf

  If !IntToBool(AutoLoot_Setting_LootSettlements)
    If SafeHasForm(Locations, akItem.GetCurrentLocation())
      Return False
    EndIf
  EndIf

  MiscObject akMisc = akItem.GetBaseObject() as MiscObject

  Return ItemHasLootableComponent(akMisc)
EndFunction

Function BuildAndProcessReferences(FormList akFilter)
  ObjectReference[] LootArray = PlayerRef.FindAllReferencesOfType(akFilter, Radius.GetValue())

  If (LootArray == None) || (LootArray.Length == 0)
    Return
  EndIf

  LootArray = FilterLootArray(LootArray)

  If (LootArray == None) || (LootArray.Length == 0)
    Return
  EndIf

  Int i = 0
  Bool bContinue = True

  While (i < LootArray.Length) && bContinue
    bContinue = PlayerRef.HasPerk(ActivePerk) && IsPlayerControlled()

    If bContinue
      ObjectReference objLoot = LootArray[i]

      If objLoot
        LootObject(objLoot)
      EndIf
    EndIf

    i += 1
  EndWhile

  If (LootArray == None) || (LootArray.Length == 0)
    Return
  EndIf

  LootArray.Clear()
EndFunction

Function AddObjectToObjectReferenceArray(ObjectReference akContainer, ObjectReference[] akArray)
  ; exclude quest items that are explicitly excluded
  If SafeHasForm(QuestItems, akContainer)
    Return
  EndIf

  Bool bAllowStealing = IntToBool(AutoLoot_Setting_AllowStealing)
  Bool bLootOnlyOwned = IntToBool(AutoLoot_Setting_LootOnlyOwned)

  AddObjectToArray(akArray, akContainer, PlayerRef, bAllowStealing, bLootOnlyOwned)
EndFunction

ObjectReference[] Function FilterLootArray(ObjectReference[] akArray)
  ObjectReference[] kResult = new ObjectReference[0]

  If akArray.Length == 0
    Return kResult
  EndIf

  Int i = 0
  Bool bContinue = True

  While (i < akArray.Length) && bContinue
    bContinue = kResult.Length <= 128 && PlayerRef.HasPerk(ActivePerk) && IsPlayerControlled()

    If bContinue
      ObjectReference kItem = akArray[i]

      If kItem
        If ItemCanBeProcessed(kItem)
          ObjectReference kContainer = kItem.GetContainer()

          If !kContainer && (kContainer != PlayerRef)
            AddObjectToObjectReferenceArray(kItem, kResult)
          EndIf
        EndIf
      EndIf
    EndIf

    i += 1
  EndWhile

  Return kResult
EndFunction

Bool Function ItemHasLootableComponent(MiscObject akItem)
  Int i = 0
  Bool bContinue = True

  ; Loop through global formlist
  While (i < AutoLoot_Globals_Components.GetSize()) && bContinue
    bContinue = PlayerRef.HasPerk(ActivePerk) && IsPlayerControlled()

    If bContinue
      ; If the component is preferred, and akItem has that component, return True
      If IntToBool(AutoLoot_Globals_Components.GetAt(i) as GlobalVariable)
        Component cmpo = AutoLoot_Filter_Components.GetAt(i) as Component

        If akItem.GetObjectComponentCount(cmpo) > 0
          Return True
        EndIf
      EndIf
    EndIf

    i += 1
  EndWhile

  Return False
EndFunction

Function LootObject(ObjectReference objLoot)
  If (objLoot == None) || (DummyActor == None)
    Return
  EndIf

  If IntToBool(AutoLoot_Setting_AllowStealing)
    If !IntToBool(AutoLoot_Setting_StealingIsHostile) && PlayerRef.WouldBeStealing(objLoot)
      objLoot.SetActorRefOwner(PlayerRef)
    EndIf
  EndIf

  objLoot.Activate(DummyActor, False)
EndFunction

; -----------------------------------------------------------------------------
; PROPERTIES
; -----------------------------------------------------------------------------

Group Actors
  Actor Property PlayerRef Auto Mandatory
  Actor Property DummyActor Auto Mandatory
EndGroup

Group Forms
  FormList Property Filter Auto Mandatory
  FormList Property QuestItems Auto Mandatory
  FormList Property AutoLoot_Filter_Components Auto Mandatory
  FormList Property AutoLoot_Globals_Components Auto Mandatory
  FormList Property Locations Auto Mandatory
EndGroup

Group Globals
  GlobalVariable Property Destination Auto Mandatory
  GlobalVariable Property Delay Auto Mandatory
  GlobalVariable Property Radius Auto Mandatory
  GlobalVariable Property AutoLoot_Setting_AllowStealing Auto Mandatory
  GlobalVariable Property AutoLoot_Setting_LootOnlyOwned Auto Mandatory
  GlobalVariable Property AutoLoot_Setting_LootSettlements Auto Mandatory
  GlobalVariable Property AutoLoot_Setting_StealingIsHostile Auto Mandatory
EndGroup

Group Timer
  Int Property TimerID Auto Mandatory
EndGroup

Group Perks
  Perk Property ActivePerk Auto Mandatory
EndGroup
