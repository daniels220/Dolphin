﻿"Filed out from Dolphin Smalltalk 7"!

MethodBrowserShell subclass: #MethodExplorerShell
	instanceVariableNames: 'historyTree historyList'
	classVariableNames: 'HistoryListSize'
	poolDictionaries: ''
	classInstanceVariableNames: ''!
MethodExplorerShell guid: (GUID fromString: '{8d4892fd-f8e1-49bd-87b5-7366078a04ff}')!
MethodExplorerShell comment: 'MethodExplorerShell is a <MethodBrowserShell> that implements a method browser tool with history tree of searches. Each browse operation (e.g. a definitions or reference search) initiated from the browser results in a new node in the tree. The node is created under the node that was current when the search was performed. This allows one to drill down by performing a series of nested search operations, with the tree maintaining the path. A history list and forward/back buttons allow one to navigate through the chronological history of searches.

Instance Variables:
	historyTree		<TreePresenter>
	historyList			<HistoryList>

Class Variables:
	HistoryListSize		<integer>

'!
!MethodExplorerShell categoriesForClass!MVP-Presenters! !
!MethodExplorerShell methodsFor!

addSearch: aBrowserEnvironment under: parentBrowserEnvironment 
	historyTree model add: aBrowserEnvironment asChildOf: parentBrowserEnvironment!

addToCommandRoute: route 
	"Update the <OrderedCollection>, path, with the receiver's contribution to the command path
	held by the <CommandPolicy>, route. Answer self to have the command policy decide where
	to go next."

	"Implementation Note: We want to make sure that the methods presenter is always
	in the route, and that it appears before SmalltalkSystem but after the receiver (if not already
	in the route)."

	route
		appendTarget: self;
		appendTarget: browserPresenter;
		appendPresenter: self!

browseMethodsIn: aBrowserEnvironment 
	self addSearch: aBrowserEnvironment under: historyTree selectionOrNil.
	historyTree selection: aBrowserEnvironment.
	self setInitialFocus!

browseMethodsInEnvironments: aCollectionOfBrowserEnvironments 
	| first |
	aCollectionOfBrowserEnvironments do: 
			[:each | 
			first ifNil: [first := each].
			self addSearch: each under: historyTree selectionOrNil].
	first ifNotNil: [historyTree selection: first].
	self setInitialFocus!

buildHistoryFutureMenu
	"Private - Answer a dynamically created future visit menu."

	^(self buildHistoryMenu: historyList upToEnd command: #historyForward:)
		text: 'Forward';
		yourself!

buildHistoryMenu: visits command: cmdSelector
	"Private - Answer a dynamically created past visit history menu."

	| popup lastEnv subMenu methods |
	popup := Menu new.
	lastEnv := nil.
	visits keysAndValuesDo: 
			[:i :each |
			| env method |
			env := each key.
			env == lastEnv
				ifFalse: 
					[methods := IdentitySet new.
					subMenu := popup addSubmenu: env displayString.
					lastEnv := env].
			method := each value ?? '(none)'.
			"We only want to add each method to the menu once"
			(methods includes: method)
				ifFalse: 
					[subMenu addCommand: (Message selector: cmdSelector argument: i) description: method displayString.
					methods add: method].
			subMenu setDefault: 1].
	popup setDefault: 1.
	^popup!

buildHistoryPastMenu
	"Private - Answer a dynamically created past visit history menu."

	^(self buildHistoryMenu: historyList past command: #historyBack:)
		text: 'Past';
		yourself!

buildPopupForCommand: aSymbol 
	"Private - Dynamically build an appropriate popup menu for aSymbol command."

	aSymbol == #historyBack ifTrue: [^self buildHistoryPastMenu].
	aSymbol == #historyForward ifTrue: [^self buildHistoryFutureMenu].
	^super buildPopupForCommand: aSymbol!

canSaveState
	"Private - Answer true if the receiver can successfully have it's state saved by #saveStateOn:. Some
	tools may not be able to save their state and therefore will not be able to be exported as
	part of a IdeaSpace save operation"

	^true!

clearSelection
	"Removes the selected method from the system"

	self perform: self deleteItCommand!

createComponents
	"Create the presenters contained by the receiver"

	super createComponents.
	historyTree := self 
				add: TreePresenter new
				name: 'historyTree'
				helpId: 10875!

createSchematicWiring
	super createSchematicWiring.
	historyTree 
		when: #selectionChanged
		send: #onTreeSelectionChanged
		to: self.
	self 
		when: #timerTick:
		send: #onTimerTick:
		to: self!

defaultHelpId
	^10874!

deleteItCommand
	historyTree hasFocus ifTrue: [^#removeHistoryNode].
	^nil!

hasFuture
	^historyList hasFuture!

hasPast
	^historyList hasPast!

historySkip: anInteger 
	"Private - Move around in the history list by the specified <integer> delta (negative for
	backwards)."

	| method history visit node |
	history := historyList.
	browserPresenter promptToSaveChanges ifFalse: [^self].
	history skip: anInteger.
	visit := history current.
	node := visit key.
	self noEventsDo: [historyTree selection: node].
	method := visit value.
	browserPresenter clearErrors.
	(method notNil and: [(method methodClass includesSelector: method selector) not]) 
		ifTrue: 
			[self statusText: ('<1p> has been deleted' expandMacrosWith: method).
			Sound warningBeep.
			method := nil].
	browserPresenter selection: method ifAbsent: []!

historyTree
	^historyTree!

initialize
	"Private - Initialize the receiver."

	super initialize.
	historyList := HistoryList new: self class historyListSize!

isSameMethod: aCompiledMethod1 as: aCompiledMethod2 
	^aCompiledMethod1 isNil 
		ifTrue: [aCompiledMethod2 isNil]
		ifFalse: 
			[aCompiledMethod2 notNil and: 
					[aCompiledMethod1 selector == aCompiledMethod2 selector 
						and: [aCompiledMethod1 methodClass == aCompiledMethod2 methodClass]]]!

killVisitTimer
	self view killTimer: 1!

methods: aBrowserEnvironment
	self browseMethodsIn: aBrowserEnvironment!

onMethodSelected
	"Private - The browserPresenter has selected a method.
	Ensure that the browserPresenter selects the appropriate text."

	super onMethodSelected.
	self setVisitTimer!

onTimerTick: anInteger 
	anInteger == 1 ifFalse: [^self].
	self killVisitTimer.
	self recordMethodVisit!

onTipTextRequired: tool 
	"Tool tip text is required for the <ToolbarItem>, tool."

	| cmd |
	cmd := tool command asSymbol.
	(cmd == #historyBack and: [historyList hasPast]) 
		ifTrue: [^'Back to <1p>' expandMacrosWith: historyList previous].
	(cmd == #historyForward and: [historyList hasFuture]) 
		ifTrue: [^'Forward to <1p>' expandMacrosWith: historyList next].
	^super onTipTextRequired: tool!

onTreeSelectionChanged
	self killVisitTimer.
	historyTree selectionOrNil
		ifNil: 
			[self caption: self class displayString.
			browserPresenter list: #()]
		ifNotNil: 
			[:env |
			self caption: env label.
			browserPresenter methods: env.
			self selectFirstMethod]!

onViewOpened
	"Private - Received when the receiver's view is been connected. "

	| toolbar |
	super onViewOpened.
	toolbar := self view viewNamed: 'historyTools'.
	toolbar presenterConnectionPoint 
		when: #dropDown:
		send: #onDropDown:
		to: self.
!

queryCommand: aCommandQuery 
	"Private - Enter details about a potential command for the receiver 
	into the <CommandQuery>."

	| selector |
	selector := aCommandQuery commandSymbol.
	#clearSelection == selector 
		ifTrue: 
			[selector := self deleteItCommand.
			selector isNil 
				ifTrue: 
					[aCommandQuery isEnabled: false.
					^true]].
	#historyBack: == selector 
		ifTrue: 
			[| dist |
			dist := aCommandQuery command arguments first.
			aCommandQuery isEnabled: historyList pastSize >= dist.
			^true].
	#historyForward: == selector 
		ifTrue: 
			[| dist |
			dist := aCommandQuery command arguments first.
			aCommandQuery isEnabled: historyList futureSize >= dist.
			^true].
	selector == #historyForward 
		ifTrue: 
			[self hasFuture 
				ifTrue: 
					[aCommandQuery
						isEnabled: true;
						text: (aCommandQuery commandDescription menuText expandMacrosWith: historyList next)]
				ifFalse: 
					[aCommandQuery
						isEnabled: false;
						text: 'Forward'].
			^true].
	selector == #historyBack 
		ifTrue: 
			[self hasPast 
				ifTrue: 
					[aCommandQuery
						isEnabled: true;
						text: (aCommandQuery commandDescription menuText expandMacrosWith: historyList previous)]
				ifFalse: 
					[aCommandQuery
						isEnabled: false;
						text: 'Back'].
			^true].
	^super queryCommand: aCommandQuery!

recordMethodVisit
	"Private - Add to the visit history - note that the current item is at the top of the history list"

	| node method |
	node := historyTree selectionOrNil.
	node isNil ifTrue: [^self].
	method := self selectedMethod.
	(historyList isEmpty or: 
			[| cur |
			cur := historyList current.
			cur key ~= node or: [(self isSameMethod: cur value as: method) not]]) 
		ifTrue: 
			[historyList addLast: node -> method.
			self invalidateUserInterface]
		ifFalse: [historyList current: node -> method]!

removeHistoryNode
	| node |
	node := historyTree selection.
	historyList removeMatching: [:visit | visit key = node].
	historyTree model remove: node.
	self invalidateUserInterface!

saveStateOn: aWriteStream 
	"Private - Write the source of a monadic block that will configure an instance of the receiver's class
	to match the state current receiver, to aWriteStream. The block expects a fresh instance of
	the receiver's class as it's parameter"

	aWriteStream nextPutAll: '[ :aMethodExplorer | aMethodExplorer historyTree model: '.
	self historyTree model literalStoreEvaluationOn: aWriteStream.
	aWriteStream
		nextPut: $.;
		cr.
	super saveStateOn: aWriteStream.
	aWriteStream nextPutAll: ' value: aMethodExplorer.'.
	aWriteStream nextPutAll: ']'!

selectFirstMethod
	^browserPresenter hasMethods 
		ifTrue: [browserPresenter selection: browserPresenter list first]
		ifFalse: [self setVisitTimer]!

setVisitTimer
	self view setTimer: 1 interval: self class historyDwellTime!

slideyPinNames
	^super slideyPinNames , #('historySlidey')! !
!MethodExplorerShell categoriesFor: #addSearch:under:!public! !
!MethodExplorerShell categoriesFor: #addToCommandRoute:!commands!public! !
!MethodExplorerShell categoriesFor: #browseMethodsIn:!public! !
!MethodExplorerShell categoriesFor: #browseMethodsInEnvironments:!public! !
!MethodExplorerShell categoriesFor: #buildHistoryFutureMenu!helpers!menus!private! !
!MethodExplorerShell categoriesFor: #buildHistoryMenu:command:!helpers!menus!private! !
!MethodExplorerShell categoriesFor: #buildHistoryPastMenu!helpers!menus!private! !
!MethodExplorerShell categoriesFor: #buildPopupForCommand:!event handling!private! !
!MethodExplorerShell categoriesFor: #canSaveState!private!saved state! !
!MethodExplorerShell categoriesFor: #clearSelection!commands!public! !
!MethodExplorerShell categoriesFor: #createComponents!initializing!public! !
!MethodExplorerShell categoriesFor: #createSchematicWiring!initializing!public! !
!MethodExplorerShell categoriesFor: #defaultHelpId!public! !
!MethodExplorerShell categoriesFor: #deleteItCommand!helpers!private! !
!MethodExplorerShell categoriesFor: #hasFuture!public!testing! !
!MethodExplorerShell categoriesFor: #hasPast!public!testing! !
!MethodExplorerShell categoriesFor: #historySkip:!commands!private! !
!MethodExplorerShell categoriesFor: #historyTree!public! !
!MethodExplorerShell categoriesFor: #initialize!initializing!private! !
!MethodExplorerShell categoriesFor: #isSameMethod:as:!helpers!private! !
!MethodExplorerShell categoriesFor: #killVisitTimer!helpers!private! !
!MethodExplorerShell categoriesFor: #methods:!accessing!public! !
!MethodExplorerShell categoriesFor: #onMethodSelected!event handling!private! !
!MethodExplorerShell categoriesFor: #onTimerTick:!event handling!private! !
!MethodExplorerShell categoriesFor: #onTipTextRequired:!event handling!private! !
!MethodExplorerShell categoriesFor: #onTreeSelectionChanged!event handling!private! !
!MethodExplorerShell categoriesFor: #onViewOpened!event handling!private! !
!MethodExplorerShell categoriesFor: #queryCommand:!commands!private! !
!MethodExplorerShell categoriesFor: #recordMethodVisit!helpers!private! !
!MethodExplorerShell categoriesFor: #removeHistoryNode!helpers!private! !
!MethodExplorerShell categoriesFor: #saveStateOn:!private!saved state! !
!MethodExplorerShell categoriesFor: #selectFirstMethod!event handling!private! !
!MethodExplorerShell categoriesFor: #setVisitTimer!helpers!private! !
!MethodExplorerShell categoriesFor: #slideyPinNames!accessing!private! !

!MethodExplorerShell class methodsFor!

browseMethodsInEnvironments: aCollectionOfBrowserEnvironment 
	| browser |
	browser := self show.
	browser browseMethodsInEnvironments: aCollectionOfBrowserEnvironment.
	^browser!

displayOn: aStream
	"Append, to aStream, a String whose characters are a representation of the receiver as a user
	would want to see it."

	aStream nextPutAll: 'Method Explorer'!

historyListSize
	^HistoryListSize ifNil: [self defaultHistoryListSize]!

historyListSize: anInteger 
	HistoryListSize := anInteger!

initialize
	"private -- class-side initalisation.

		self initialize.
	"

	Smalltalk developmentSystem registerTool: self.
	self canUseIdeaSpace: true.
	self historyListSize: nil!

resource_Default_view
	"Answer the literal data from which the 'Default view' resource can be reconstituted.
	DO NOT EDIT OR RECATEGORIZE THIS METHOD.

	If you wish to modify this resource evaluate:
	ViewComposer openOn: (ResourceIdentifier class: self selector: #resource_Default_view)
	"

	^#(#'!!STL' 4 788558 10 ##(Smalltalk.STBViewProxy) ##(Smalltalk.ShellView) 34 27 nil nil 8 #(13565952 65536) 416 nil 655878 ##(Smalltalk.ThemeColor) #toolBackground nil 517 nil nil nil 416 788230 ##(Smalltalk.BorderLayout) 1 1 410 ##(Smalltalk.Toolbar) 34 25 nil 416 34 2 8 1140853580 131073 528 nil nil nil 517 nil nil nil 528 327686 ##(Smalltalk.Color) #default 8 1921592800 170 192 34 12 410 ##(Smalltalk.ReferenceView) 34 14 nil 528 34 2 8 1140850688 131073 672 nil nil nil 5 nil nil nil 672 1180230 1 ##(Smalltalk.ResourceIdentifier) ##(Smalltalk.Toolbar) #resource_Find_tools nil 983302 ##(Smalltalk.MessageSequence) 138 144 34 1 721670 ##(Smalltalk.MessageSend) #createAt:extent: 34 2 328198 ##(Smalltalk.Point) 1297 1 882 109 51 672 983302 ##(Smalltalk.WINDOWPLACEMENT) 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 136 2 0 0 0 0 0 0 190 2 0 0 25 0 0 0] 8 #() 882 193 193 nil 27 8 'findTools' 410 ##(Smalltalk.ReferenceView) 34 14 nil 528 34 2 8 1140850688 131073 1024 nil nil nil 5 nil nil nil 1024 738 ##(Smalltalk.Toolbar) #resource_Search_tools nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 615 1 882 437 51 1024 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 51 1 0 0 0 0 0 0 13 2 0 0 25 0 0 0] 976 992 nil 27 8 'searchTools' 410 ##(Smalltalk.ReferenceView) 34 14 nil 528 34 2 8 1140850688 131073 1264 nil nil nil 5 nil nil nil 1264 738 ##(Smalltalk.Toolbar) #resource_Edit_tools nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 1051 1 882 247 51 1264 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 13 2 0 0 0 0 0 0 136 2 0 0 25 0 0 0] 976 992 nil 27 8 'editTools' 410 ##(Smalltalk.ReferenceView) 34 14 nil 528 34 2 8 1140850688 131073 1504 nil nil nil 5 nil nil nil 1504 738 ##(Smalltalk.Toolbar) #resource_Image_tools nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 1 1 882 63 51 1504 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 0 0 0 0 31 0 0 0 25 0 0 0] 976 992 nil 27 8 'imageTools' 410 ##(Smalltalk.ReferenceView) 34 14 nil 528 34 2 8 1140850688 131073 1744 nil nil nil 5 nil nil nil 1744 738 ##(Smalltalk.Toolbar) #resource_History_tools nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 1405 1 882 169 51 1744 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 190 2 0 0 0 0 0 0 18 3 0 0 25 0 0 0] 976 992 nil 27 8 'historyTools' 410 ##(Smalltalk.ReferenceView) 34 14 nil 528 34 2 8 1140850688 131073 1984 nil nil nil 5 nil nil nil 1984 738 ##(Smalltalk.Toolbar) #resource_Smalltalk_tools nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 63 1 882 553 51 1984 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 31 0 0 0 0 0 0 0 51 1 0 0 25 0 0 0] 976 992 nil 27 8 'smalltalkTools' 170 192 976 138 144 976 nil nil 1 nil 882 33 33 nil nil 656198 1 ##(Smalltalk.FlowLayout) 1 1 1 770 138 144 34 2 834 #createAt:extent: 34 2 882 1 1 882 1779 51 528 834 #updateSizePosted 976 528 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 0 0 0 0 121 3 0 0 25 0 0 0] 34 6 1504 1984 1024 1264 672 1744 992 nil 27 410 ##(Smalltalk.StatusBar) 34 18 nil 416 34 2 8 1140850956 1 2480 nil nil nil 5 nil 263174 ##(Smalltalk.Font) nil true 459014 ##(Smalltalk.LOGFONT) 8 #[245 255 255 255 0 0 0 0 0 0 0 0 0 0 0 0 144 1 0 0 0 0 0 0 3 2 1 34 77 105 99 114 111 115 111 102 116 32 83 97 110 115 32 83 101 114 105 102 0 59 0 0 0 0 247 0 5 86 111 1] 882 193 193 nil 2480 nil 8 1921382976 170 192 34 6 853766 ##(Smalltalk.StatusBarItem) 1 -1 2480 nil 459270 ##(Smalltalk.Message) #displayString 8 #() ##(Smalltalk.IconicListAbstract) nil 8 'version' 2690 1 45 2480 nil nil 787814 3 ##(Smalltalk.BlockClosure) 0 nil 1180966 ##(Smalltalk.CompiledExpression) 5 1 ##(Smalltalk.UndefinedObject) 8 'doIt' 8 '[:modified | modified ifTrue: [Smalltalk developmentSystem changedIcon imageIndex]]' 8 #[33 105 17 122 45 159 160 161 106 60 106] 721414 ##(Smalltalk.Association) #Smalltalk ##(Smalltalk) #developmentSystem #changedIcon #imageIndex 2816 7 257 nil nil 8 'modified' 2690 1 841 2480 nil ##(Smalltalk.BasicListAbstract) ##(Smalltalk.IconicListAbstract) nil 8 'errors' 34 3 2784 2960 2704 1115142 ##(Smalltalk.StatusBarNullItem) 513 1 2480 nil nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 1 713 882 1779 41 2480 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 100 1 0 0 121 3 0 0 120 1 0 0] 8 #() 992 nil 27 nil nil 410 ##(Smalltalk.ContainerView) 34 15 nil 416 34 2 8 1140850688 131073 3200 nil nil nil 5 nil nil nil 3200 498 1 1 nil nil nil nil 410 ##(Smalltalk.ContainerView) 34 15 nil 3200 34 2 8 1409286144 131073 3280 nil nil nil 5 nil nil nil 3280 1180166 ##(Smalltalk.ProportionalLayout) 170 176 976 true 170 192 34 2 410 ##(Smalltalk.ReferenceView) 34 14 nil 3280 34 2 8 1140916224 131073 3424 nil nil nil 5 nil nil nil 3424 738 ##(Smalltalk.MethodWorkspace) #resource_Default_view nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 1 337 882 1779 327 3424 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 168 0 0 0 121 3 0 0 75 1 0 0] 976 992 nil 27 8 'source' nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 1 1 882 1779 663 3280 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 0 0 0 0 121 3 0 0 75 1 0 0] 34 3 410 ##(Smalltalk.ContainerView) 34 15 nil 3280 34 2 8 1140850688 131073 3824 nil nil nil 5 nil nil nil 3824 3346 138 ##(Smalltalk.Dictionary) 34 1 2914 410 ##(Smalltalk.Splitter) 34 12 nil 3824 34 2 8 1140850688 1 3952 nil nil nil 517 nil nil nil 1510470 1 ##(Smalltalk.DraggableViewInteractor) 3952 nil 1 #left nil nil nil 882 1 1 882 9 9 nil 4048 nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 885 1 882 11 327 3952 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 186 1 0 0 0 0 0 0 191 1 0 0 163 0 0 0] 8 #() 992 nil 27 1 false 170 192 34 4 410 ##(Smalltalk.ReferenceView) 34 14 nil 3824 34 2 8 1140850688 131073 4272 nil nil nil 5 nil nil nil 4272 738 ##(Smalltalk.MethodBrowser) #resource_Method_browser_method_list nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 895 1 882 885 327 4272 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 191 1 0 0 0 0 0 0 121 3 0 0 163 0 0 0] 976 992 nil 27 8 'methodlist' 410 ##(Smalltalk.SlideyInneyOuteyThing) 34 23 nil 3824 34 2 8 1409286144 131073 4512 nil nil nil 517 nil nil nil 4512 656710 1 ##(Smalltalk.CardLayout) 138 144 34 1 2914 8 'History' 410 ##(Smalltalk.TreeView) 34 27 nil 410 ##(Smalltalk.SlidingCardTray) 34 22 nil 4512 34 2 8 1140850688 131073 4704 nil nil nil 5 nil nil nil 4704 4592 170 192 34 2 4672 8 'historyTree' nil 410 ##(Smalltalk.TabViewXP) 34 28 nil 4512 34 2 8 1140851328 1 4816 590662 2 ##(Smalltalk.ListModel) 138 144 34 1 4656 nil 1310726 ##(Smalltalk.IdentitySearchPolicy) nil nil 1 nil nil nil 4816 nil 8 1921705120 ##(Smalltalk.BasicListAbstract) ##(Smalltalk.IconicListAbstract) 1049926 1 ##(Smalltalk.IconImageManager) nil nil nil nil nil #noIcons nil nil nil nil nil 770 138 144 34 3 834 #createAt:extent: 34 2 882 1 1 882 885 327 4816 834 #basicSelectionsByIndex: 34 1 8 #(1) 4816 834 #tcmSetExtendedStyle:dwExStyle: 8 #(-1 0) 4816 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 0 0 0 0 186 1 0 0 163 0 0 0] 8 #() 992 nil 27 nil 4512 882 33 33 1050182 1 ##(Smalltalk.ButtonInteractor) 4704 nil 1 590342 ##(Smalltalk.Rectangle) 882 785 3 882 817 35 nil 1180998 4 ##(Smalltalk.CommandDescription) #togglePin 8 'Pin or Unpin the tray' 1 1 nil nil nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 57 9 882 821 311 4704 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 28 0 0 0 4 0 0 0 182 1 0 0 159 0 0 0] 34 1 4672 992 nil 27 34 2 8 1140916775 1025 4672 590918 3 ##(Smalltalk.TreeModel) nil 4960 525062 ##(Smalltalk.TreeNode) nil nil nil 170 192 976 608 nil 5 265030 4 ##(Smalltalk.Menu) nil true 34 4 984134 2 ##(Smalltalk.CommandMenuItem) 1 5378 #browseMessageDefinitions 8 '&Definitions of...' 1 1 nil nil nil 5746 1 5378 #browseMessageReferences 8 '&References to...' 1 1 nil nil nil 983366 1 ##(Smalltalk.DividerMenuItem) 4097 5746 1 5378 #clearSelection 8 'Re&move' 1 1 nil nil nil 8 '' nil 134217729 nil nil nil nil nil nil nil 4672 nil 8 1921400880 2722 #displayString 8 #() ##(Smalltalk.IconicListAbstract) 5008 nil nil nil nil nil 170 176 976 nil #noIcons 1 170 ##(Smalltalk.PluggableLookupTable) 976 770 138 144 34 2 834 #createAt:extent: 34 2 882 1 37 882 821 275 4672 834 #contextMenu: 34 1 5712 4672 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 18 0 0 0 154 1 0 0 155 0 0 0] 8 #() 992 nil 27 4672 nil nil nil 170 192 976 nil 4816 4704 882 201 201 401 1 31 nil nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 1 1 882 885 327 4512 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 0 0 0 0 186 1 0 0 163 0 0 0] 34 2 4704 4816 992 nil 27 8 'historySlidey' nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 1 1 882 1779 327 3824 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 0 0 0 0 121 3 0 0 163 0 0 0] 34 3 4512 3952 4272 992 nil 27 410 ##(Smalltalk.Splitter) 34 12 nil 3280 34 2 8 1140850688 1 6592 nil nil nil 517 nil nil nil 4018 6592 nil 1 #left nil nil nil 4048 4064 nil 4048 nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 1 327 882 1779 11 6592 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 163 0 0 0 121 3 0 0 168 0 0 0] 8 #() 992 nil 27 3424 992 nil 27 170 192 34 2 3280 8 'browser' nil 770 138 144 34 1 834 #createAt:extent: 34 2 882 1 51 882 1779 663 3200 930 8 #[44 0 0 0 0 0 0 0 1 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 0 0 0 0 25 0 0 0 121 3 0 0 100 1 0 0] 34 1 3280 992 nil 27 170 192 34 4 2480 8 'statusbar' 528 8 'toolbar' nil 461638 4 ##(Smalltalk.MenuBar) nil true 34 8 5698 nil true 34 8 5746 1 5378 #fileNew 8 '&New Workspace' 9373 1 263494 3 ##(Smalltalk.Icon) nil true 1572870 ##(Smalltalk.ImageRelativeFileLocator) 8 'NewWorkspace.ico' 2032142 ##(Smalltalk.STBExternalResourceLibraryProxy) 8 'dolphindr7.dll' nil nil nil 5746 1 5378 #fileOpen 8 '&Open Workspace...' 9375 1 7234 nil true 7280 8 'OpenWorkspace.ico' 7328 nil nil 5746 1 5378 #fileFileIn 8 '&File In...' 1 1 7234 nil true 7280 8 'FileIn.ico' 7328 nil nil 5858 4097 5746 1 5378 #saveImage 8 'Sa&ve Image' 1 1 7234 nil true 7280 8 'Snapshot.ico' 7328 nil nil 5746 1 5378 #smalltalkExit 8 'E&xit Dolphin' 1 1 7234 nil true 7280 8 'PowerSwitch.ico' 7328 nil nil 5858 4097 5746 1 5378 #exit 8 '&Close' 17639 1 788806 1 ##(Smalltalk.TextTileIcon) $\x2716 nil nil nil nil nil 1 nil nil nil nil 8 '&File' nil 134217729 nil nil 43693 nil nil 5698 nil true 34 13 5746 1 5378 #undo 8 '&Undo' 9397 1 7234 nil true 7280 8 'EditUndo.ico' 7328 nil nil 5858 4097 5746 1 5378 #cutSelection 8 'Cu&t' 9393 1 7234 nil true 7280 8 'EditCut.ico' 7328 nil nil 5746 1 5378 #copySelection 8 '&Copy' 9351 1 7234 nil true 7280 8 'EditCopy.ico' 7328 nil nil 5746 1 5378 #pasteClipboard 8 '&Paste' 9389 1 7234 nil true 7280 8 'EditPaste.ico' 7328 nil nil 5746 1 5378 #editDelete 8 '&Delete' 1 1 7234 nil true 7280 8 'EditClear.ico' 7328 nil nil 5698 nil true 34 2 5746 1 5378 #reformatSource 8 '&Source' 9391 1 nil nil nil 5746 1 5378 #reformatComment 8 '&Comment' 9367 1 nil nil nil 8 'Ref&ormat' nil 134217729 nil nil 43709 nil nil 5858 4097 5746 1 5378 #selectAll 8 'Select &All' 9347 1 nil nil nil 5858 4097 5746 1 5378 #editFind 8 '&Find...' 9357 1 7234 nil true 7280 47 786694 ##(Smalltalk.ShellLibrary) nil nil 5746 1 5378 #findNext 8 'Find &Next' 1253 1 7234 nil true 7280 8 'FindNext.ico' 7328 nil nil 5746 1 5378 #findReplace 8 '&Replace...' 9361 1 nil nil nil 8 '&Edit' nil 134217729 nil nil 43719 nil nil 5698 nil true 34 17 5746 1 5378 #browseIt 8 '&Browse It' 9349 1 7234 nil true 7280 8 'ClassBrowserShell.ico' 7328 nil nil 5746 1 5378 #displayIt 8 '&Display It' 9353 1 7234 nil true 7280 8 'DisplayIt.ico' 7328 nil nil 5746 1 5378 #printIt 8 '&Print It' 9377 1 7234 nil true 7280 8 'PrintIt.ico' 7328 nil nil 5746 1 5378 #evaluateIt 8 '&Evaluate It' 9355 1 7234 nil true 7280 8 'EvaluateIt.ico' 7328 nil nil 5746 1 5378 #inspectIt 8 '&Inspect It' 9363 1 7234 nil true 7280 8 'InspectIt.ico' 7328 nil nil 5746 1 5378 #debugIt 8 'Deb&ug It' 1269 1 7234 nil true 7280 8 'Debugger.ico' 7328 nil nil 5746 1 5378 #fileItIn 8 'Fi&le It In' 1 1 nil nil nil 5858 4097 5746 1 5378 #browseDefinitions 8 'Defi&nitions' 1271 1 nil nil nil 5746 1 5378 #browseReferences 8 '&References' 5367 1 nil nil nil 5858 4097 5746 2097153 5378 #accept 8 '&Accept' 9383 1 nil nil nil 5746 1 5378 #reformatAccept 8 'Refor&mat/Accept' 13479 1 nil nil nil 5858 4097 5698 nil true 34 14 5746 1 5378 #renameVariable 8 'Re&name <1d>...' 1 1 nil nil nil 5858 4097 5746 1 5378 #extractToTemporary 8 'Extract to &Temporary...' 9385 1 nil nil nil 5746 1 5378 #extractMethod 8 'E&xtract Method...' 9371 1 nil nil nil 5746 1 5378 #extractToComponent 8 'Extract to &Component...' 1 1 nil nil nil 5746 1 5378 #inlineMessage 8 'Inline &Message' 13467 1 nil nil nil 5858 4097 5746 1 5378 #inlineTemporary 8 '&Inline Temporary' 13481 1 nil nil nil 5746 1 5378 #moveTempToInnerScope 8 'Move to Inner &Scope' 9655 1 nil nil nil 5746 1 5378 #convertTempToInstVar 8 'Con&vert to Instance Variable' 1 1 nil nil nil 5858 4097 5746 1 5378 #addParameterToMessage 8 '&Add Parameter to <1d>...' 1 1 nil nil nil 5746 1 5378 #inlineParameter 8 'In&line Parameter' 1 1 nil nil nil 5746 1 5378 #removeParameter 8 'Remove &Parameter' 1 1 nil nil nil 8 'Re&factorings' #codeRefactoringsMenu 134217729 7234 nil true 7280 8 'Refactoring.ico' 7328 nil 43765 nil nil 5858 4097 5698 nil true 34 7 5746 1 5378 #toggleAutoCompletion 8 '&Auto-complete' 1 1 nil nil nil 5746 1 5378 #toggleIndentationGuides 8 'Indentation &Guides' 1 1 nil nil nil 5746 1 5378 #toggleLineEndings 8 'Line &Endings' 1 1 7762 $¶ 8 'Arial' nil nil nil nil 1 nil nil nil nil 5746 1 5378 #toggleLineNumbers 8 'Line N&umbers' 1 1 nil nil nil 5746 1 5378 #toggleStyling 8 '&Syntax Coloring' 1 1 nil nil nil 5746 1 5378 #toggleWhitespace 8 'W&hitespace' 1 1 nil nil nil 5746 1 5378 #toggleWordWrap 8 '&Word Wrap' 1 1 nil nil nil 8 '&Options' nil 134217729 7234 nil true 7280 8 'Preferences.ico' 7328 nil 43781 nil nil 8 '&Workspace' nil 134217729 nil nil 43783 nil nil 5698 nil true 34 11 5698 nil true 8 #() 8 'De&finitions of' #definitionsMenu 1 nil nil 43785 nil nil 5698 nil true 8 #() 8 '&References to' #referencesMenu 1 nil nil 43787 nil nil 5698 nil true 34 11 5746 1 5378 #browseReferencesToGlobal 8 'References to Global...' 1 1 nil nil nil 5746 1 5378 #browseContainingText 8 'C&ontaining Text...' 1 1 7234 nil true 7280 8 'SearchText.ico' 7328 nil nil 5746 1 5378 #browseMethodCategory 8 'Cate&gory...' 1 1 7234 nil true 7280 8 'Category.ico' 7328 nil nil 5746 1 5378 #browseCompilationFailures 8 'Compilation &Failures' 1 1 nil nil nil 5746 1 5378 #browseCompilationIssues 8 'Compilation Iss&ues' 1 1 nil nil nil 5858 4097 5746 1 5378 #browseMethodPackages 8 'Package <s>' 1 1 7234 nil true 7280 8 'Package.ico' 7328 nil nil 5746 1 5378 #browseMethodClasses 8 'Class <s>' 1 1 nil nil nil 5858 4097 5746 1 5378 #browseMethodHistory 8 '&Change History' 1 1 7234 nil true 7280 8 'MethodHistory.ico' 7328 nil nil 5746 1 5378 #browseAllChangedMethods 8 '&All Changed Methods' 1 1 nil nil nil 8 '&Browse other' nil 134217729 nil nil 43807 nil nil 5858 4097 5746 1 5378 #removeMethod 8 '&Delete' 1 1 7234 nil true 7280 8 'EditClear.ico' 7328 nil nil 5698 nil true 34 17 5746 1 5378 #renameMethod 8 'Re&name' 1 1 nil nil nil 5746 1 5378 #renameMethodReferences 8 'Rename Re&ferences...' 1 1 nil nil nil 5746 1 5378 #safeRemoveMethods 8 'Rem&ove' 1 1 nil nil nil 5858 4097 5746 1 5378 #addParameter 8 'Add &Parameter...' 1 1 nil nil nil 5698 nil true 8 #() 8 'Remo&ve Parameter' #removeParameterMenu 134217729 nil nil 43819 nil nil 5698 nil true 8 #() 8 'Rena&me Parameter' #renameParameterMenu 134217729 nil nil 43821 nil nil 5698 nil true 8 #() 8 '&Inline Parameter' #inlineParameterMenu 134217729 nil nil 43823 nil nil 5858 4097 5698 nil true 8 #() 8 'Rename &Temporary' #renameTempMenu 134217729 nil nil 43825 nil nil 5698 nil true 8 #() 8 'Convert Temp to Inst. Var.' #convertTempToInstVarMenu 134217729 nil nil 43827 nil nil 5858 4097 5746 1 5378 #inlineAllSelfSends 8 'Inline &Self Sends' 1 1 nil nil nil 5746 1 5378 #pushUpMethods 8 'Push &Up' 9325 1 nil nil nil 5746 1 5378 #pushDownMethods 8 'Push &Down' 9327 1 nil nil nil 5746 1 5378 #overrideMethods 8 'Ove&rride <1d>' 1 1 nil nil nil 5746 1 5378 #moveMethod 8 'Move to &Component...' 1 1 nil nil nil 8 'Refactorin&gs' #methodRefactoringsMenu 134217729 7234 nil true 7280 8 'Refactoring.ico' 7328 nil 43839 nil nil 5858 4097 5746 1 5378 #methodPackage 8 '&Package...' 1 1 7234 nil true 7280 8 'Package.ico' 7328 nil nil 5698 nil true 8 #() 8 'Add to &Category' #addCategoryMenu 134217729 nil nil 43843 nil nil 5698 nil true 8 #() 8 'Re&move from Category' #removeCategoryMenu 134217729 nil nil 43845 nil nil 5746 1 5378 #togglePrivate 8 'Pri&vate' 1 1 nil nil nil 8 '&Method' nil 134217729 nil nil 43849 nil nil 5698 nil true 34 3 5746 1 5378 #undoChange 8 '&Undo <1d>' 1 1 7234 nil true 7280 8 'EditUndo.ico' 7328 nil nil 5746 1 5378 #redoChange 8 '&Redo <1d>' 1 1 7234 nil true 7280 8 'EditRedo.ico' 7328 nil nil 5746 1 5378 #clearChangeHistory 8 'Clear Change &History' 1 1 7234 nil true 7280 8 'MethodHistoryErase.ico' 7328 nil nil 8 'H&istory' nil 134217729 nil nil 43857 nil nil 5698 nil true 8 #() 8 '&Tools' #toolsMenu 134217729 nil nil 43859 nil nil 5698 nil true 8 #() 8 'Wi&ndow' #windowMenu 134217729 nil nil 43861 nil nil 5698 nil true 34 15 5746 1 5378 #helpContents 8 '&Contents' 1025 1 7234 nil true 7280 8 'Help.ico' 7328 nil nil 5746 1 5378 #help 8 'On this &Tool' 1249 1 nil nil nil 5746 1 5378 #helpWhatsThis 8 'What''s This?' 5345 1 nil nil nil 5858 4097 5746 1 5378 #learnSmalltalk 8 'Learn Smalltalk' 1 1 7762 $\x1F393 nil 594 #orchid 594 #white nil nil 1 nil nil nil nil 5858 4097 5746 1 5378 #helpWhatsNew 8 'What''s &New' 1 1 nil nil nil 5746 1 5378 #helpGuidedTour 8 '&Guided Tour' 1 1 nil nil nil 5746 1 5378 #helpTutorials 8 'Tutorials' 1 1 nil nil nil 5858 4097 5746 1 5378 #objectArtsHomePage 8 'Object Arts Homepage' 1 1 7234 nil true 7280 8 '!!APPLICATION' 7328 nil nil 5746 1 5378 #dolphinNewsgroup 8 'Dolphin Newsgroup/Forum' 1 1 nil nil nil 5746 1 5378 #dolphinWikiWeb 8 'Dolphin WikiWeb' 1 1 nil nil nil 5858 4097 5746 1 5378 #aboutDolphin 8 '&About Dolphin Smalltalk' 1 1 7762 $\x1F42C nil nil 594 #darkSlateBlue nil nil 1 nil nil nil nil 8 '&Help' nil 134217729 nil nil 43885 nil nil 8 '' nil 134217729 nil nil nil nil nil nil nil nil 1 nil nil nil nil 1 nil nil 770 138 144 34 3 834 #createAt:extent: 34 2 882 261 261 882 1811 871 416 834 #text: 34 1 8 'Method Explorer' 416 834 #updateMenuBar 976 416 930 8 #[44 0 0 0 0 0 0 0 0 0 0 0 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 255 130 0 0 0 130 0 0 0 11 4 0 0 53 2 0 0] 34 3 528 3200 2480 992 nil 27 )! !
!MethodExplorerShell class categoriesFor: #browseMethodsInEnvironments:!instance creation!public! !
!MethodExplorerShell class categoriesFor: #displayOn:!displaying!public! !
!MethodExplorerShell class categoriesFor: #historyListSize!accessing!public! !
!MethodExplorerShell class categoriesFor: #historyListSize:!accessing!public! !
!MethodExplorerShell class categoriesFor: #initialize!initializing!private! !
!MethodExplorerShell class categoriesFor: #resource_Default_view!public!resources-views! !

