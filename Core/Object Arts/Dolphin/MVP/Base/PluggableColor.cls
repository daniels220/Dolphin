﻿"Filed out from Dolphin Smalltalk 7"!

VirtualColor subclass: #PluggableColor
	instanceVariableNames: 'valuable'
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
PluggableColor guid: (GUID fromString: '{74b2076a-a07a-4203-aa78-b3fc0ad65e7c}')!
PluggableColor comment: '`PluggableColor` is the class of `Color`s that dynamically determine their actual `Color` value by evaluating a `<niladicValuable>`.

## Instance Variables:
  `valuable`		`<niladicValuable>` evaluated to determine the actual colour to use each time it is required.

'!
!PluggableColor categoriesForClass!Drawing! !
!PluggableColor methodsFor!

actualColor
	^valuable value!

printOn: aPuttableStream
	self basicPrintOn: aPuttableStream!

setValuable: aNiladicValuable 
	valuable := aNiladicValuable!

stbSaveOn: anSTBOutFiler
	"Override back to default implementation"

	anSTBOutFiler saveObject: self! !
!PluggableColor categoriesFor: #actualColor!private!testing! !
!PluggableColor categoriesFor: #printOn:!printing!public! !
!PluggableColor categoriesFor: #setValuable:!initializing!private! !
!PluggableColor categoriesFor: #stbSaveOn:!binary filing!public! !

!PluggableColor class methodsFor!

stbReadFrom: anSTBInFiler format: anSTBClassConversion 
	"Override back to default implementation"

	^anSTBInFiler readObjectOfClass: self format: anSTBClassConversion!

with: aNiladicValuable 
	<primitive: 157>
	^self basicNew setValuable: aNiladicValuable! !
!PluggableColor class categoriesFor: #stbReadFrom:format:!binary filing!public! !
!PluggableColor class categoriesFor: #with:!instance creation!public! !

