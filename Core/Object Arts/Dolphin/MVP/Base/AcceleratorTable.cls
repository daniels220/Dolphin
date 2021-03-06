﻿"Filed out from Dolphin Smalltalk 7"!

GraphicsTool subclass: #AcceleratorTable
	instanceVariableNames: 'commands'
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
AcceleratorTable guid: (GUID fromString: '{87b4c632-026e-11d3-9fd7-00a0cc3e4a32}')!
AcceleratorTable comment: '`AcceleratorTable` is the class used to represent the table of "accelerator" key sequences associated with a top-level view. These key-sequences provide keyboard shortcuts to commands on the menu or toolbar (or any other command sources).

## Instance Variables:
  `commands`		`IdentityDictionary` mapping between a key code `<integer>` and the associated `CommandDescription`
'!
!AcceleratorTable categoriesForClass!Graphics-Tools! !
!AcceleratorTable methodsFor!

addCommand: aCommandDescription 
	"Add a new accelerator to the table. The argument, vKeyCode, is an integer with the
	following bit format:
		0-8	virtual key code
		1	extended key bit
		9-16 accelerator key modifier flags (e.g. FALT).
	Note that if the same accelerator key combination is added more then once, then the latest
	addition will take precedence."

	commands at: aCommandDescription acceleratorKey put: aCommandDescription!

basicFree
	"Private - Free up the Accelerator resource handle.
	Ignore any error return (e.g. due to an invalid handle)."

	UserLibrary default destroyAcceleratorTable: handle!

commands
	^commands!

commands: anArrayOfCommandDescription 
	commands := anArrayOfCommandDescription!

createHandle
	"Private - Realizes the handle for the accelerator table and registers all selectors.
	This does not usually happen until the first key press occurs in a new shell window."

	"NB: CreateAcceleratorTable requires a pointer to a variable sized array of ACCEL structures."

	| accels count cmds i |
	cmds := self commands.
	count := cmds size.
	accels := StructureArray length: count elementClass: ACCEL.
	accels beUnfinalizable.	"Nothing to free here"
	i := 1.
	cmds keysAndValuesDo: [:vkey :command ||struct |
		struct := accels at: i.
		struct
			fVirt: ((vkey bitShift: -9) bitOr: FVIRTKEY);
			key: (vkey bitAnd: 16rFF);
			cmd: command id	"Always add virtual key flag, or modifiers ignored".
		i := i + 1].
	^UserLibrary default createAcceleratorTable: accels cEntries: count!

includes: commandSymbol 
	"Answer whether there is an entry in the accelerator table for commandSymbol."

	^self commands anySatisfy: [:each | each commandSymbol == commandSymbol]!

initialize
	"Private - Initialize the receiver."

	super initialize.
	commands := IdentityDictionary new!

isEmpty
	"Answer whether any accelerator keys have been set."

	^commands isEmpty!

notEmpty
	"Answer whether any accelerator keys have been set."

	^self isEmpty not!

postCopy
	"Apply any final flourish to the copy that may be required in order to ensure that the copy
	does not share non-shareable  state with the original. Answer the receiver."

	super postCopy.
	commands := commands copy.
	^self! !
!AcceleratorTable categoriesFor: #addCommand:!adding!public! !
!AcceleratorTable categoriesFor: #basicFree!private!realizing/unrealizing! !
!AcceleratorTable categoriesFor: #commands!accessing!public! !
!AcceleratorTable categoriesFor: #commands:!initializing!private! !
!AcceleratorTable categoriesFor: #createHandle!private!realizing/unrealizing! !
!AcceleratorTable categoriesFor: #includes:!public!searching! !
!AcceleratorTable categoriesFor: #initialize!initializing!private! !
!AcceleratorTable categoriesFor: #isEmpty!public!testing! !
!AcceleratorTable categoriesFor: #notEmpty!public!testing! !
!AcceleratorTable categoriesFor: #postCopy!copying!public! !

!AcceleratorTable class methodsFor!

icon
	"Answers an Icon that can be used to represent this class"

	^Keyboard icon!

invariantKeyStringFromCode: anInteger
	"Answer a localised accelerator string corresponding to the <integer> accelerator key code, anInteger, as described by the invariant keyboard layout."

	^self keyStringFromCode: anInteger keyboard: Keyboard invariant!

keyCode: vkInteger modifiers: maskInteger
	"Answer an accelerator key code (an <integer> packed with a virtual key code and accelerator modifiers) created from the 9-bit <integer> virtual key code (the high bit is used to mark extended keys), vkInteger, and the modifier flags <integer> (e.g. FALT), maskInteger."

	^(vkInteger bitAnd: 16r1FF) bitOr: (maskInteger bitShift: 9)!

keyCodeFromInvariantString: aString
	"Answer an <integer> accelerator key code (a value packed with a virtual key code and accelerator modifiers) created from the invariant (English) accelerator key description,
	aString."

	^self keyCodeFromString: aString keyboard: Keyboard invariant!

keyCodeFromString: aString
	"Answer an <integer> accelerator key code (a packed value containing the virtual key code and accelerator modifiers) created from the localised accelerator key description, aString."

	^self keyCodeFromString: aString keyboard: Keyboard default!

keyCodeFromString: aString keyboard: aKeyboard
	"Answer an accelerator key code (an integer packed with a virtual key code and accelerator modifiers) created from the key descriptions of the specified <Keyboard>."

	| keys |
	keys := self splitKeyString: aString.
	keys isEmpty ifTrue: [^0].
	^self keyCode: (aKeyboard virtualKeyFromString: keys last) modifiers: (self keyModifiers: keys keyboard: aKeyboard)!

keyModifierNames: anInteger keyboard: aKeyboard
	"Private - Answer a <sequencedReadableCollection> of <String>s , being the names of the virtual key modifiers in the <integer> mask, anInteger, in the specified Keyboard layout."

	| answer |
	answer := OrderedCollection new.
	self
		keyModifierNames: anInteger
		keyboard: aKeyboard
		do: [:each | answer add: each value].
	^answer!

keyModifierNames: anInteger keyboard: aKeyboard do: aMonadicValuable
	| modifierKeys |
	modifierKeys := aKeyboard modifierKeys.
	##({FCONTROL. FSHIFT. FALT})
		do: [:each | (anInteger anyMask: each) ifTrue: [aMonadicValuable value: (modifierKeys keyAtValue: each)]]!

keyModifiers: anArrayOfInvariantKeyStrings keyboard: aKeyboard
	| modifiers |
	modifiers := aKeyboard modifierKeys.
	^anArrayOfInvariantKeyStrings inject: FVIRTKEY
		into: [:sum :each | sum bitOr: (modifiers at: each ifAbsent: [0])]!

keySeparator
	"Private - Answer the <Character> used to separate the key names in a chord."

	^$+!

keyStringFromCode: anInteger
	"Answer a localised accelerator string corresponding to the <integer> accelerator key code, anInteger, as described by the current keyboard layout."

	^self keyStringFromCode: anInteger keyboard: Keyboard default!

keyStringFromCode: anInteger keyboard: aKeyboard
	"Answer a localised accelerator string corresponding to the accelerator key code, anInteger, as described by the specified Keyboard layout."

	^self
		keyStringFromCode: (anInteger bitAnd: 16r1FF)
		modifiers: (anInteger bitShift: -9)
		keyboard: aKeyboard!

keyStringFromCode: vkInteger modifiers: maskInteger
	"Private - Answer an accelerator string constructed for the specified virtual key and modifiers for the current keyboard layout."

	^self
		keyStringFromCode: vkInteger
		modifiers: maskInteger
		keyboard: Keyboard default!

keyStringFromCode: vkInteger modifiers: maskInteger keyboard: aKeyboard
	| keyString sep |
	sep := self keySeparator.
	keyString := String writeStream: 12.
	self
		keyModifierNames: maskInteger
		keyboard: aKeyboard
		do: 
			[:each |
			keyString
				nextPutAll: each;
				nextPut: sep].
	keyString nextPutAll: (aKeyboard
				keyNameFromVKey: ((vkInteger bitAnd: 16r1FF) bitOr: (maskInteger bitAnd: -16r100))
				ifNone: ['']).
	^keyString contents!

splitKeyCode: anInteger
	"Answer a 2-element <Array> containing a virtual key code <integer> and accelerator table modifier flags <integer> from the <integer> accelerator key code argument."

	^{anInteger bitAnd: 16r1FF. anInteger bitShift: -9}!

splitKeyString: aString
	"Answer an <Array> of <String>s containing the names of the keys specified in the <readableString> accelerator key chord, aString. Note that this must not contain any spaces."

	^aString subStrings: self keySeparator!

stbConvertFrom: anSTBClassFormat 
	"Version 1 changes format of the 'commands' (formerly 'accelerators') instance variable."

	^
	[:data | 
	| newInstance map |
	newInstance := self basicNew.
	1 to: data size do: [:i | newInstance instVarAt: i put: (data at: i)].
	map := IdentityDictionary new.
	newInstance commands do: [:each | map at: each key put: each value].
	newInstance commands: map.
	newInstance]!

stbVersion
	^1! !
!AcceleratorTable class categoriesFor: #icon!constants!public! !
!AcceleratorTable class categoriesFor: #invariantKeyStringFromCode:!enquiries!public! !
!AcceleratorTable class categoriesFor: #keyCode:modifiers:!helpers!public! !
!AcceleratorTable class categoriesFor: #keyCodeFromInvariantString:!enquiries!public! !
!AcceleratorTable class categoriesFor: #keyCodeFromString:!enquiries!public! !
!AcceleratorTable class categoriesFor: #keyCodeFromString:keyboard:!enquiries!public! !
!AcceleratorTable class categoriesFor: #keyModifierNames:keyboard:!enquiries!private! !
!AcceleratorTable class categoriesFor: #keyModifierNames:keyboard:do:!enquiries!private! !
!AcceleratorTable class categoriesFor: #keyModifiers:keyboard:!enquiries!private! !
!AcceleratorTable class categoriesFor: #keySeparator!constants!private! !
!AcceleratorTable class categoriesFor: #keyStringFromCode:!enquiries!public! !
!AcceleratorTable class categoriesFor: #keyStringFromCode:keyboard:!enquiries!public! !
!AcceleratorTable class categoriesFor: #keyStringFromCode:modifiers:!enquiries!helpers!private! !
!AcceleratorTable class categoriesFor: #keyStringFromCode:modifiers:keyboard:!enquiries!helpers!private! !
!AcceleratorTable class categoriesFor: #splitKeyCode:!helpers!public! !
!AcceleratorTable class categoriesFor: #splitKeyString:!helpers!public! !
!AcceleratorTable class categoriesFor: #stbConvertFrom:!binary filing!private! !
!AcceleratorTable class categoriesFor: #stbVersion!binary filing!public! !

