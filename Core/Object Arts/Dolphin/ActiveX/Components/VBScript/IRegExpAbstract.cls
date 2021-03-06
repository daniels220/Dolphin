﻿"Filed out from Dolphin Smalltalk 7"!

IDispatch subclass: #IRegExpAbstract
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	classInstanceVariableNames: ''!
IRegExpAbstract guid: (IID fromString: '{427E61D6-DDA9-489B-9102-C745EC40641B}')!
IRegExpAbstract isAbstract: true!
IRegExpAbstract comment: '<IRegExpAbstract> is an abstract class implementing methods common between the various Microsoft VBScript IRegExp COM interfaces.'!
!IRegExpAbstract categoriesForClass!COM-Interfaces! !
!IRegExpAbstract methodsFor!

execute: aString 
	"Answer an <IMatchCollection> containing all sub-strings of the <String> argument which
	match this regular expression."

	| answer |
	answer := self matchCollectionClass newPointer.	
	self Execute: aString ppMatches: answer.
	^answer asArray!

Execute: sourceString ppMatches: ppMatches
	^self subclassResponsibility!

get_Global: pGlobal
	"Private - Get the value of the 'Global' property of the receiver.

		HRESULT __stdcall Global(
			[out, retval]VARIANT_BOOL* pGlobal);"

	<virtual stdcall: hresult 12 varbool*>
	^self invalidCall: _failureCode!

get_IgnoreCase: pIgnoreCase
	"Private - Get the value of the 'IgnoreCase' property of the receiver.

		HRESULT __stdcall IgnoreCase(
			[out, retval]VARIANT_BOOL* pIgnoreCase);"

	<virtual stdcall: hresult 10 varbool*>
	^self invalidCall: _failureCode!

get_Pattern: pPattern
	"Private - Get the value of the 'Pattern' property of the receiver.

		HRESULT __stdcall Pattern(
			[out, retval]BSTR* pPattern);"

	<virtual stdcall: hresult 8 bstr*>
	^self invalidCall: _failureCode!

global
	"Answer whether the regular expression should be tested against all possible matches in a
	string, false by default."

	| answer |
	answer := (VARIANT_BOOL new).
	self get_Global: answer.
	^answer asObject
!

global: aBoolean 
	"Set whether the regular expression should be tested against all possible matches in a
	string, false by default."

	self put_Global: aBoolean!

ignoreCase
	"Answer whether the regular expression search should be case insensitive, false by default."

	| answer |
	answer := (VARIANT_BOOL new).
	self get_IgnoreCase: answer.
	^answer asObject
!

ignoreCase: aBoolean 
	"Set whether the regular expression search should be case insensitive, false by default."

	self put_IgnoreCase: aBoolean!

isExtensible
	"Answer whether the receiver may add methods at run-time."

	^false!

isVBCollection
	"Answer whether the receiver is a VB style collection."

	^false!

matchCollectionClass
	^self subclassResponsibility!

pattern
	"Answer the regular expression search <String>. See
	http://msdn.microsoft.com/library/en-us/dnclinic/html/scripting051099.asp for help and
	examples."

	| answer |
	answer := BSTR new.
	self get_Pattern: answer.
	^answer asObject
!

pattern: aString 
	"Set the regular expression search <String>. See
	http://msdn.microsoft.com/library/en-us/dnclinic/html/scripting051099.asp for help and
	examples."

	self put_Pattern: aString!

put_Global: pGlobal
	"Private - Set the value of the 'Global' property of the object wrapped by the 
	 receiver to the <varbool> argument, pGlobal.

		HRESULT __stdcall Global(
			[in]VARIANT_BOOL pGlobal);"

	<virtual stdcall: hresult 13 varbool>
	^self invalidCall: _failureCode!

put_IgnoreCase: pIgnoreCase
	"Private - Set the value of the 'IgnoreCase' property of the object wrapped by the 
	 receiver to the <varbool> argument, pIgnoreCase.

		HRESULT __stdcall IgnoreCase(
			[in]VARIANT_BOOL pIgnoreCase);"

	<virtual stdcall: hresult 11 varbool>
	^self invalidCall: _failureCode!

put_Pattern: pPattern
	"Private - Set the value of the 'Pattern' property of the object wrapped by the 
	 receiver to the <bstr> argument, pPattern.

		HRESULT __stdcall Pattern(
			[in]BSTR pPattern);"

	<virtual stdcall: hresult 9 bstr>
	^self invalidCall: _failureCode!

replace: sourceString replaceString: replaceString
	"Answer the <String> result of performing a regular expression based search/replace, where
	the regular expression itself defines the text to search for, sourceString is the source text against
	which the search/replace is performed, and replaceString is the replacement pattern."

	^self subclassResponsibility!

test: aString 
	"Answer whether the <String> argument matches the current regular expression."

	| answer |
	answer := VARIANT_BOOL new.
	self Test: aString pMatch: answer.
	^answer asObject!

Test: sourceString pMatch: pMatch
	^self subclassResponsibility! !
!IRegExpAbstract categoriesFor: #execute:!operations!public! !
!IRegExpAbstract categoriesFor: #Execute:ppMatches:!private! !
!IRegExpAbstract categoriesFor: #get_Global:!private! !
!IRegExpAbstract categoriesFor: #get_IgnoreCase:!private! !
!IRegExpAbstract categoriesFor: #get_Pattern:!private! !
!IRegExpAbstract categoriesFor: #global!properties!public! !
!IRegExpAbstract categoriesFor: #global:!properties!public! !
!IRegExpAbstract categoriesFor: #ignoreCase!properties!public! !
!IRegExpAbstract categoriesFor: #ignoreCase:!properties!public! !
!IRegExpAbstract categoriesFor: #isExtensible!public!testing! !
!IRegExpAbstract categoriesFor: #isVBCollection!public!testing! !
!IRegExpAbstract categoriesFor: #matchCollectionClass!constants!private! !
!IRegExpAbstract categoriesFor: #pattern!properties!public! !
!IRegExpAbstract categoriesFor: #pattern:!properties!public! !
!IRegExpAbstract categoriesFor: #put_Global:!private! !
!IRegExpAbstract categoriesFor: #put_IgnoreCase:!private! !
!IRegExpAbstract categoriesFor: #put_Pattern:!private! !
!IRegExpAbstract categoriesFor: #replace:replaceString:!operations!public! !
!IRegExpAbstract categoriesFor: #test:!operations!public! !
!IRegExpAbstract categoriesFor: #Test:pMatch:!private! !

!IRegExpAbstract class methodsFor!

clsid
	"Private - Answer the CLSID of the associated coclass, RegExp. When VBScript RegExp 5.5 is
	installed, the coclass supports IRegExp2, but on older installations (such as a standard
	Win98 2e) only IRegExp is supported."

	^CLSID fromString: '{3F4DACA4-160D-11D2-A8E9-00104B365C9F}'
!

pattern: aString
	^self new pattern: aString! !
!IRegExpAbstract class categoriesFor: #clsid!constants!private! !
!IRegExpAbstract class categoriesFor: #pattern:!instance creation!public! !

