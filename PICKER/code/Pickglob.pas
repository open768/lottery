unit Pickglob;
{
  VERSION HISTORY

	1.0 - (1996) basic animated component, no tickets, list of selected numbers
	1.1 - animated component tarted up with bitmapped balls
	1.2 - list replaced with ticket showing numbers
		numbers in play can be selected.
	1.3 - bug fixed in grab_ball, was grabbing from all balls regardless
		if they were out of play.
	2.0 - drawn numbers added. TstringGrid is too buggy for editing
		so fudged with arrayof controls. analysis capability, frequency
		analysis, tracks guessed numbers
	2.1 - previous numbers shows when numbers were last drawn.
	2.2 - analysis module is specific to UK lottery players and provided
		as a separate free program, ability to change the number pool.
	2.3 - corrected minor bug, adding numbers caused highlighting to go wonky
		added tab to show when numbers were first drawn
	2.4 - corrected orgnisation of globals to reduce duplicating code
		saves and reads preferences
	2.5 - added a ballrack, partly animated.
		minor bugfix in caption on go_button, now uses constants
	2.6 - removed floating point from ticket componnent
		when program expires, it whinges but does not cripple
	2.7 - ticket now greys and crosses out numbers not in play
	2.8 - ticket behaviour changed, ini file different, no picker changes.
	2.9 - machine made faster by removing floating point
		ops when caculating sin and cos. Now uses cache.
		magic numbers removed from machine component.
	3.0 - balls released at any angle between 60 and -60 degrees
	3.1 - custom bubble help used.
	3.2 - fixed error for numbers >=54, purple bitmap added
	3.3 - plugged in shareware checking component
	3.4 - added rudimentary sounds
	3.5 - Added sorting, "Pick from" now called "options"
	3.51- bug fixed on sorting
	3.6 - rendered balls used for ticket
	3.61- rendered balls used for ballrack too.
	3.62- bugfix to rendered ticket, increased security.
	3.63- palette optimisation fixed, still doesnt
		work properly. machine component has a plain mode
	4.0 - certain angles caused picker to only drop first 5 balls
		added another ticket to show which balls have been dropped
		** Price reduction to $5 **
	4.01- increased to a selection from 99 balls.
	4.02- flickering reduced using retainedcanvas which does
		offscreemn and timer manipulation.
	4.03- added start at zero capability.
	4.04- added random drop.
	4.05- added display of numbers.
		replaced random drop with listbox of differend drop styles
	4.06 - random energy loss introduced to machine
	4.07 - rebuild, corrupt shareware module
	4.08 - must have lostsome code, rewrote prefs and ball server as classes
	4.09 - added ability to clear registration details back to unregistered
	4.10 - copy numbers to clipboard
	5.0  - Analysis Tools now can use any number set
	5.1  - plugged in HTML help
	5.2  - replaced lotteryflags with Tintlist - completed
	5.21 - sharewarechecker imposes dd/mm/yyyy date format
	******************************************************************************
	1.0	- ported to Delphi 3 - so long delphi1! reset back to version 1.0
	1.1	- 17/9/2000
		ticket component allows overlapping numbers	and mutliple bonus numbers
		picker fully works under D3
	1.1.1	- 9/10/2000
		also change release angle by dragging mouse.
		removed numeric display of angle
	1.1.2	- 11/10/2000
		corrected dragging of picker rack
	1.1.3	- 17/10/2000
		balls now drop from correct places on rach
		rack vanishes when all dropped
	1.1.4	- 10/12/2000
		removed dependence on windows API for ini files
		as this was horrendously flaky. wrote own more
		resilient ini file routines.
	1.1.5 - 23/12/2000
		added ability to specify sequences, now have to
		modify lottery machine to cope
	1.1.6	- 31/12/2000
		completed code for picking sequences,
		need to be able to save + load different sequences
		need to improve help files
	1.1.7 - 01/01/01
		minor bugfix - when restarted no balls dropped out.
	1.1.8	- 02/01/01
		new ini file routines were barfing when file not present
	1.1.9	- 27/06/01 - RELEASE 
		- builds with runtime dll
		- uses HKEY_CURRENT_USER in registry
	1.1.10 - runtime DLL didnt save any download size
		- 01/09/01 changed way sequences are stored
		- 02/09/01 added ability to reuse a number after its been dropped.
	1.1.11 - 17/09/01 radically altered inifilecode to use overloading
	1.2.0 - changes options box to use TpageControl

	******************************************************************************
	2.0.0 - 19/10/01 strengthening of shareware - uses disk serial number
			- 22/10/01 full internationalisation of interface with lang.ini
		2.0.1 - 2/11/01 - machine reactivates all balls in sequence
		2.0.2 - 4/11/01
			- added keep picking options (not used)
			- improved bounce so that balls dont bounce up and down on the spot.
	2.0.3 - 5/11/01 created TrenderedBalls - object orientation of ball blitting code
			- speeded up lo res drawing y using same mechanism as rendered
	2.0.4 -8/11/01
			- added initialisation and finalisation sections to TrenderedBalls
			- added black ball to resource files
			- changed arrays to use High() and Low() functions
			- added new disaply style to lottery ticket.
			- started work on Tballgrid
	2.0.5 - 11/11/01 - completed Tballgrid and integrated with picker.
	2.1.0 - 12/11/01 - RELEASE
			- continue picking until stop clicked
			- use remaining numbers to pick from
   2.1.1 - 23/01/02 -full language support and added language selection ulitity
   2.1.2 - 06/02/02
		- added background bitmap support so that you can see all
			your pervy pictures
   2.1.2 - 06/02/02 - GPF bug in loading pictures duh ! fixed
   2.1.3 - 07/02/02am - added chevron buttons
   2.1.4 - 07/02/02 - remove ball bitmaps from resources and into bitmaps
   2.1.5 - 08/02/02 - bugfix -
		- missing bitmaps shown as crossed
		- minimum of 1 number selected for picking.
   2.1.6 - 13/02/02
		- image loading in separate thread;
		- balls stop after sequence 1 - problem dissapeared
   2.1.7 - 14/02/02
		- threads were not being freed
		- corrected dragging
		- added new property sweepingrelease to allow the rack to be swept as the
			balls are released no code yet
   2.1.8 - 05/03/02
		- auto generates coloured bitmaps needed - bit dull needs work on mapping colour.
   2.1.9 - ball colours can be configured using lottcolours.ini
   2.1.10 - 07/03/02
		- ball colours can be selected per game
		- split packages up into paglis/paglis lottery/ paglis ebook
	2.1.11 - 04-01-03
		- slotted in thashtree - everything still works
	2.1.12 - 09-01-03
		- updated misclib
	2.1.13 - 09-02-03
		- updated help system. make sure it works.
	2.1.14 - 16-02-03
		- updated auto translation, still need to match up controls with labels
	2.2.0 - 18-02-03 * RELEASE *
		- translation resizes controls and containers and install program
	2.2.1 - 06-04-03
		- extra sound effect for ball being ejected from machine.
	2.2.2 - 23-05-04
		- rebuilt - ball rendered on window used to remember
	2.2.3 - 02-06-04
		- cosmetic changes as suggested by dave
			- [DONE] remove registered message at startup - include in title bar
			- [DONE] option to choose which lottery to run (default uk)
			- [DONE] FUDGED - all tool tips have white line underneath them
			- [REJECT] options - selection tab have numbers as balls not squares
			- [DONE] options - reset option , no cancel option
			- [REJECT] options - select, turn off all even numbers and turn off all odd numbers
					still some remain! [sunil: display a warning to user]
			- [DONE] can turn off numbers but not turn back on again - should be a toggle.
			- [DONE] tool tips for min/max give (turn off even/odd numbers)
			- [DONE] options - options tooltips for each option
			- [TBD] when numbers are picked the number get a black background and is
					  obscured, becomes unreadable, perhaps make flash with brighter color?
					  [sunil:no animation, remove black square]
			- [REJECT] picked numbers are not sorted into numerical order.
			- [REJECT] picked numbers window is not updated as balls are picked perhaps change
					to call it results or somethings that implies a set of numbers that have
					been picked?
			- [DONE - rename ok button] about box needs ok,cancel,buy buttons. People like to always be able to cancel!
			- [TBD] I clicked on buy and got "Hey, I couldn't find the register web file"??
			- [DONE] about box www.paglis.co.uk cannot click on it to get web page up!
			- [DONE] the swirly thing can I click on it to pick a ball now??
	2.3.0 - 13-10-04
		- 	finally implemented registration through the web - hurrah! emails
			no longer need to be sent containing registration details
			TBD - what happens for people behind firewalls?
			TBD - replace inifiles with inprocess database.
	2.3.1 - 05-06-05
		- allow backdrop folder to be configured
    2.3.2 - 24-04-09
        -   built for d6 - huzzah
    2.3.3 - 27-04-09
        -   gravity option
        -   changed format of rememberd numbers
    2.3.4 - 22-09-10
        -  made randomness optional.

	TBD - update help files
}

interface

const
	MAJOR_VERSION = 2;
	MINOR_VERSION = '3.2';
	LONG_PROGRAM_NAME = 'picker Free';
	COPYRIGHT = 'Copyright 1996 - 2013 #Chicken Katsu#' ;
	URL = 'http://www.chickenkatsu.co.uk/';

	PICKER_BARF_SOUND = 'barf.wav';
	PICKER_SELECT_SOUND = 'select.wav';
	PICKER_FINISHED_SOUND = 'finish.wav';
	PICKER_PICKING_SOUND = 'ready.wav';
	PICKER_EJECT_SOUND = 'eject.wav';
implementation
end.


