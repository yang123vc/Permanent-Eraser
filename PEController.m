//  PEController.m
//  PermanentEraser
//
//  Created by Chad Armstrong on Mon Jun 02 2003.
//  Copyright (c) 2003-2007 Edenwaith. All rights reserved.
//

// How to add a badge using Cocoa
// http://www.cocoabuilder.com/archive/message/cocoa/2004/2/3/95988

// How to add a Hot Key using Cocoa
// http://www.unsanity.org/archives/2002_10.php

// Description of the Mac OS X version of statfs
// http://developer.apple.com/documentation/Darwin/Reference/Manpages/man2/statfs.2.html

// Erasing free space examples

// EXAMPLE 1
// nice -n 20 dd bs=50m if=/dev/random of=/tmp/$UID/temp.$$ count=1
// nice -n 20 srm -z /tmp/$UID/temp.$$
//
//	EXAMPLE 2
//	#!/bin/sh
//
//	set +e +u
//	dd if=/dev/urandom of=/tmp/_shred_free_space
//	sync; sync
//	srm /tmp/_shred_free_space
//	sync; sync

// Time Machine Utility: http://fernlightning.com/doku.php?id=software:misc:tms

// Erase a CD-RW:  hdiutil burn (-erase|-fullerase) -device (something or another...check into this)
// Also check out: drutil erase (quick | full)
// Also: diskutil eraseOptical [quick] device
// diskutil eraseOptical /dev/disk3
// diskutil also has other options, such as zeroDisk, randomDisk, etc.
// diskutil secureErase [freespace] level device
// The diskutil tip taken from the Erase Selected Disc AppleScript
// diskutil list -- lists out available discs & partitions


#import "PEController.h"
#import "NSEvent+ModifierKeys.h"
#import "PreferencesController.h"

@implementation PEController


// =========================================================================
// (id) init
// -------------------------------------------------------------------------
// Initialize variables and set up notifications.
// -------------------------------------------------------------------------
// Created: 2. June 2003 14:20
// Version: September 2009
// =========================================================================
- (id) init 
{
    self = [super init];

    fm					= [NSFileManager defaultManager];
    trash_files			= [[NSMutableArray alloc] init];
	badge				= [[CTProgressBadge alloc] init];
    pEraser				= nil; 		// initialize the NSTask
    files_were_dropped 	= NO;
    uid					= [[NSString alloc] initWithFormat:@"%d", getuid()];
//	uid					= [NSString stringWithFormat: @"%d", getuid()];	// This has issues and doesn't save properly on Mac OS 10.3 and 10.4
//	uid					= [[NSNumber numberWithInt: getuid()] stringValue]; 
 	originalIcon		= [NSImage imageNamed:@"PE"]; 
	end_angle			= 90.0;
	lastPercentageCD	= 0;
	totalFilesSize		= 0;
	
	firstTimeHere				= YES;
	wasCanceled					= NO;
	beepBeforeTerminating		= YES;
	suppressCannotEraseWarning	= NO;
	isCurrentlyErasingDisc		= NO;
	
	Gestalt(gestaltSystemVersion, (SInt32 *) &osVersion);	// Set OS Version
	
	prefs = [[NSUserDefaults standardUserDefaults] retain];
	   
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(doneErasing:) 
												 name:NSTaskDidTerminateNotification 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(appWillTerminateNotification:) 
												 name:NSApplicationWillTerminateNotification 
											   object:NSApp];

	// If the ALT/Option key is pressed when PE is launched, do not show
	// the warning dialog.  This is similar to holding down the Option
	// key when selecting the Empty Trash menu from Finder.
	if ([NSEvent isOptionKeyDown] == YES)
	{
		warnBeforeErasing = NO;
		suppressCannotEraseWarning = YES;
	}
	else
	{
		warnBeforeErasing = YES;
	}
 
    return self;
}


// =========================================================================
// (void) dealloc
// -------------------------------------------------------------------------
// Clean up after the program by deallocing space and unnotifying notifications
// -------------------------------------------------------------------------
// Created: 2. June 2003 14:20
// Version: 27 November 2009 23:23
// =========================================================================
- (void) dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSTaskDidTerminateNotification object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSApplicationWillTerminateNotification object: nil];	
	
	[badge release];
	[pipe release];
    [pEraser release];
	pEraser = nil;
    [uid release];
    [trash_files release];
	
    [super dealloc];
}


// =========================================================================
// (void) appWillTerminateNotification: (NSNotification *)aNotification 
// -------------------------------------------------------------------------
// Call this when the application is quitting.  Clean up the app icon
// so the badge doesn't remain.
// -------------------------------------------------------------------------
// Created: 24 October 2005 20:57
// Version: 11 March 2007
// =========================================================================
- (void) appWillTerminateNotification: (NSNotification *)aNotification 
{
	NSImage *icon = [NSImage imageNamed:@"PE"];

	[NSApp setApplicationIconImage:icon];	
}


// =========================================================================
// (void) awakeFromNib
// -------------------------------------------------------------------------
// Brings focus to the window.  Otherwise, it is greyed out when running.
// -------------------------------------------------------------------------
// Created: 2. June 2003 14:20
// Version: 1 January 2012 23:28
// =========================================================================
- (void) awakeFromNib 
{
	[theWindow setBackgroundColor:[NSColor colorWithCalibratedRed: 0.909 green: 0.909 blue: 0.909 alpha:1.0]];
//	[theWindow setBackgroundColor:[NSColor colorWithCalibratedRed: 0.22 green: 0.22 blue: 0.22 alpha:1.0]];
	[theWindow display];  // redraw the window to display the light grey background.
	[theWindow center];	// center the window on the screen
	[erasing_msg setStringValue:NSLocalizedString(@"PreparingMessage", nil)];
	
	// Use a spinning indeterminate progress meter when retrieving the list of files
	[indicator setIndeterminate: YES];
	[indicator setUsesThreadedAnimation:YES];
    [indicator startAnimation: self];

	// retrieve preference value for warnBeforeErasing
	// defaults write com.edenwaith.permanenteraser WarnBeforeErasing -bool NO
	// defaults write com.edenwaith.permanenteraser WarnBeforeErasing -bool YES
	if (warnBeforeErasing != NO)
	{
		if ([prefs objectForKey:@"WarnBeforeErasing"] != nil)
		{
			if ([prefs boolForKey:@"WarnBeforeErasing"] == YES)
			{
				warnBeforeErasing = YES;
			}
			else
			{
				warnBeforeErasing = NO;
			}
		}
		else
		{
			warnBeforeErasing = YES;
			// [prefs setBool:NO forKey: @"WarnBeforeErasing"];
		}
	}
	
	
	if ([prefs objectForKey:@"BeepBeforeTerminating"] != nil)
	{
		if ([prefs boolForKey:@"BeepBeforeTerminating"] == YES)
		{
			beepBeforeTerminating = YES;
		}
		else
		{
			beepBeforeTerminating = NO;
		}
	}
	else
	{
		beepBeforeTerminating = YES;
	}
	
	
	if ([prefs objectForKey: @"OpticalDiscErasingLevel"] != nil)
    {
		discErasingLevel = [[NSMutableString alloc] initWithString:[prefs objectForKey: @"OpticalDiscErasingLevel"]];
    }
	else
	{
		discErasingLevel = [[NSMutableString alloc] initWithString:@"Complete"];
	}
	
	if ([prefs objectForKey: @"FileErasingLevel"] != nil)
    {
		fileErasingLevel = [[NSMutableString alloc] initWithString:[prefs objectForKey: @"FileErasingLevel"]];
    }
	else
	{
		// Assign a default fileErasingLevel
	}
	
	[self checkInstalledPlugins];
	
}


// =========================================================================
// (void) applicationDidFinishLaunching: (NSNotification *)
// -------------------------------------------------------------------------
// Need to make the PEController a delegate of the File Owner
// -------------------------------------------------------------------------
// Created: 2. June 2003
// Version: 20 August 2007 22:00
// =========================================================================
- (void) applicationDidFinishLaunching: (NSNotification *) aNotification
{
    if (files_were_dropped == YES)
    {
        [self erase];
    }
    else // Search for files in .Trash and .Trashes
    {
        BOOL isDir;
        id object = nil;
        int j = 0;
        NSMutableString *currentDirectory = [[NSMutableString alloc] init];
        NSDirectoryEnumerator *enumerator;
        
        NSArray *volumes = [[NSArray alloc] initWithArray: [fm directoryContentsAtPath: @"/Volumes"]];
        
		// Note: It seems that it thinks that .DS_Store is also a volume.  Avoid this.
        for (j = 0; j < [volumes count]; j++)
        {
            // Check to see if the .Trashes exist, and if so, get the contents
            // of the .Trashes and add them to trash_files (full path)
            [currentDirectory setString: [[[@"/Volumes/" stringByAppendingPathComponent: [volumes objectAtIndex: j]]  
                                        stringByAppendingPathComponent: @".Trashes"]
                                        stringByAppendingPathComponent: uid]];
                                        
            if ( [fm fileExistsAtPath: currentDirectory isDirectory:&isDir] && isDir )
            {
                enumerator = [fm enumeratorAtPath: currentDirectory];
                
                while (object = [enumerator nextObject])
                {
					
                    // check for bundled files, i.e. .app, .rtfd, etc.
                    if ( [fm fileExistsAtPath: [currentDirectory stringByAppendingPathComponent: object] isDirectory:&isDir] && isDir &&
                        [[NSWorkspace sharedWorkspace] isFilePackageAtPath: [currentDirectory stringByAppendingPathComponent: object]] )
                    {
						[self addFileToArray: [currentDirectory stringByAppendingPathComponent: object]];
                        [enumerator skipDescendents];
                    }
                    else
                    {
						totalFilesSize += [self fileSize: [currentDirectory stringByAppendingPathComponent: object]];
                        // this will reverse the array so a directory will be erased last after it is empty
						[self addFileToArray: [currentDirectory stringByAppendingPathComponent: object]];
                    }
                }
            }            
        }
        
        // Get the files in the home account's Trash
        enumerator = [fm enumeratorAtPath:[@"~/.Trash/" stringByExpandingTildeInPath]];
        
        while(object = [enumerator nextObject])
        {
			// NSLog(@"%@", [[@"~/.Trash/" stringByExpandingTildeInPath] stringByAppendingPathComponent: object]);
            // check for bundled files, i.e. .app, .rtfd, etc.
            if ( [fm fileExistsAtPath: [[@"~/.Trash/" stringByExpandingTildeInPath] stringByAppendingPathComponent: object] isDirectory:&isDir] && isDir &&
                 [[NSWorkspace sharedWorkspace] isFilePackageAtPath: [[@"~/.Trash/" stringByExpandingTildeInPath] stringByAppendingPathComponent: object]] == YES )
            {
				// Generate a dictionary and insert that into the trash_files array
				[self addFileToArray: [[@"~/.Trash/" stringByExpandingTildeInPath] stringByAppendingPathComponent: object]];
                [enumerator skipDescendents];	
            }
            else
            {
				// Generate a dictionary and insert that into the trash_files array
                // this will reverse the array so a directory will be erased last after it's empty
				[self addFileToArray: [[@"~/.Trash/" stringByExpandingTildeInPath] stringByAppendingPathComponent: object]];				
            }
        }
        
        [volumes dealloc];
        [currentDirectory dealloc];
		
        [self erase];
    }
}


- (void) application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    BOOL isDir;
	BOOL isDir2;
    id object = nil;
    files_were_dropped = YES;
	int fn_idx = 0;
	
//	NSLog(@"Filenames count: %d", [filenames count]);
	
	for (fn_idx = 0; fn_idx < [filenames count]; fn_idx++)
	{
		NSString *filename = [filenames objectAtIndex: fn_idx];
//		NSLog(@"Filename: %@", filename);
		
	// Set this up to identify only burnable discs
	if ([self isVolume: filename] == YES && [self isErasableDisc: filename])
	{
		[self addFileToArray: filename];
	}
	else if ( [fm fileExistsAtPath: filename isDirectory:&isDir] && isDir &&
			 [[NSWorkspace sharedWorkspace] isFilePackageAtPath: filename] == NO && 
			 [self isFileSymbolicLink: filename] == NO)
    {
        NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath: filename];
		
		[self addFileToArray: filename];
        
        while (object = [enumerator nextObject])
        {
			// if an item within the folder is a package
			if ( [fm fileExistsAtPath: [filename stringByAppendingPathComponent: object] isDirectory:&isDir2] && isDir2 &&
				[[NSWorkspace sharedWorkspace] isFilePackageAtPath: [filename stringByAppendingPathComponent: object]] == YES )
            {
				[self addFileToArray: [filename stringByAppendingPathComponent: object]];
                [enumerator skipDescendents];
            }
            else
            {				 
				[self addFileToArray: [filename stringByAppendingPathComponent: object]];
            }
            
        }
		
    }
    else
    {
		[self addFileToArray: filename];		
    }
		
	}
    
    if (!timer)
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.0
												 target: self
											   selector: @selector(addNewFiles:)
											   userInfo: nil
												repeats: YES];
    }
	
}

/*
// =========================================================================
// (void) application:(NSApplication*) openFile:
// -------------------------------------------------------------------------
// This method is only called when a file is dragged-n-dropped onto the
// PE icon.  The timer is called to add each of the new files.
// -------------------------------------------------------------------------
// Created: 21. April 2004 
// Version: 29 June 2009 21:25
// =========================================================================
- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    BOOL isDir;
	BOOL isDir2;
    id object = nil;
    files_were_dropped = YES;

	// Set this up to identify only burnable discs
	if ([self isVolume: filename] == YES && [self isErasableDisc: filename])
	{
		[self addFileToArray: filename];
	}
	else if ( [fm fileExistsAtPath: filename isDirectory:&isDir] && isDir &&
         [[NSWorkspace sharedWorkspace] isFilePackageAtPath: filename] == NO && 
		 [self isFileSymbolicLink: filename] == NO)
    {
        NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath: filename];
		
		[self addFileToArray: filename];
        
        while (object = [enumerator nextObject])
        {
			// if an item within the folder is a package
			if ( [fm fileExistsAtPath: [filename stringByAppendingPathComponent: object] isDirectory:&isDir2] && isDir2 &&
                 [[NSWorkspace sharedWorkspace] isFilePackageAtPath: [filename stringByAppendingPathComponent: object]] == YES )
            {
				[self addFileToArray: [filename stringByAppendingPathComponent: object]];
                [enumerator skipDescendents];
            }
            else
            {				 
				[self addFileToArray: [filename stringByAppendingPathComponent: object]];
            }
            
        }

    }
    else
    {
		[self addFileToArray: filename];		
    }
    
    if (!timer)
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.0
                         target: self
                         selector: @selector(addNewFiles:)
                         userInfo: nil
                         repeats: YES];
    }

    return YES;
}
*/

// =========================================================================
// (void) addFileToArray: (NSString *) filename
// -------------------------------------------------------------------------
// 
// -------------------------------------------------------------------------
// Created: 29 June 2009 22:30
// Version: 23 May 2010 15:51
// =========================================================================
- (void) addFileToArray: (NSString *) filename
{
	PEFile *tempPEFile = [[PEFile alloc] initWithPath: filename];
	BOOL isDir3;
	
	// Symbolic link
	[tempPEFile setIsSymbolicLink: [self isFileSymbolicLink: filename]];
	
	// File size
	if ([fm fileExistsAtPath: filename isDirectory:&isDir3] && isDir3 &&
		[tempPEFile isSymbolicLink] == NO )
	{
		[tempPEFile setIsDirectory: YES];
		if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath: filename] == YES)
		{
			[tempPEFile setIsPackage: YES];
			[tempPEFile setFilesize: [self fileSize: filename]];
		}
		else if ([self isVolume: filename] == YES && [self isErasableDisc: filename])	// erasable disc
		{
			[tempPEFile setIsPackage: NO];
			[tempPEFile setFilesize: [self fileSize: filename]];
		}
		else	// otherwise, just a directory
		{
			[tempPEFile setIsPackage: NO];
			[tempPEFile setFilesize: 1];
		}
	}
	else
	{
		[tempPEFile setFilesize: [self fileSize: filename]];
		[tempPEFile setIsDirectory: NO];
		[tempPEFile setIsPackage: NO];
	}
	
	// Is Volume + Is Erasable Disc
	if ([self isVolume: filename] == YES)
	{
		[tempPEFile setIsVolume: NO];
		if ([self isErasableDisc: filename] == YES)
		{
			[tempPEFile setIsErasableDisc: YES];
		}
		else
		{
			[tempPEFile setIsErasableDisc: NO];
		}
		
	}
	else
	{
		[tempPEFile setIsVolume: NO];
		[tempPEFile setIsErasableDisc: NO];
	}
	
	// Resource Fork
	[tempPEFile setHasResourceFork: [self containsResourceFork: filename]];
	
	// Calculate total file size
	if ( ([tempPEFile isErasableDisc] == YES) || ([tempPEFile isDirectory] == NO) )
	{
		totalFilesSize += [tempPEFile filesize];
	}

	// Packages are treated as one file so it looks like just the bundle is being erased
	if ([tempPEFile isPackage] == YES)
	{
		totalFilesSize += [tempPEFile filesize];
		[tempPEFile setNumberOfFiles: [self countNumberOfFiles: [tempPEFile path]]];
	}
	else
	{
		if ([tempPEFile hasResourcefork] == YES)
		{
			[tempPEFile setNumberOfFiles: 2];
		}
		else
		{
			[tempPEFile setNumberOfFiles: 1]; // For all other files, folders, and non-bundles, set to 1
		}
	}
			
	[trash_files insertObject: tempPEFile atIndex: 0];
	
	[tempPEFile release];
}


// =========================================================================
// (unsigned long long) countNumberOfFiles: (NSString *) path
// -------------------------------------------------------------------------
// 
// -------------------------------------------------------------------------
// Created: 23 August 2009
// Version: 23 August 2009
// =========================================================================
- (unsigned long long) countNumberOfFiles: (NSString *) path
{
	unsigned long long numFiles = 0;
	
	NSDirectoryEnumerator *package_enumerator;
	id object = nil;
	BOOL isDir;
	
	package_enumerator = [fm enumeratorAtPath: path];
	
	while (object = [package_enumerator nextObject])
	{
		if ([fm fileExistsAtPath: [path stringByAppendingPathComponent: object] isDirectory:&isDir] && isDir == NO)
		{
			if ([self containsResourceFork: [path stringByAppendingPathComponent: object]] == YES)
			{
				numFiles+=2;
			}
			else
			{
				numFiles++;
			}
		}
	}
	
	return (numFiles);	
}


// =========================================================================
// (void) checkInstalledPlugins
// -------------------------------------------------------------------------
// Check if a plug-in is installed, and if so, update to the most up-to-date
// version, if necessary
// -------------------------------------------------------------------------
// Created: 2 January 2012 14:11
// Version: 6 January 2012 17:44
// =========================================================================
- (void) checkInstalledPlugins
{
	NSString *oldPluginPath = nil;
	NSString *newPluginPath = nil;
	
	// Get installed plugin path and app's plugin path
	if (osVersion >= 0x00001060)	// 10.6 or later
	{
		oldPluginPath = [@"~/Library/Services/Erase.workflow" stringByExpandingTildeInPath];
		newPluginPath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent: @"Erase.workflow"];
		
	}
	else if (osVersion >= 0x0000104)	// Mac OS 10.4 + 10.5
	{
		// Should this be 0x0000104 or 0x00001040?  Do they both work?
		oldPluginPath = [@"~/Library/Workflows/Applications/Finder/Permanent Eraser.workflow" stringByExpandingTildeInPath];
		newPluginPath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent: @"Permanent Eraser.workflow"];
	}
	
	// Check if plugin is installed
	if ([fm fileExistsAtPath: oldPluginPath] == YES && [fm fileExistsAtPath: newPluginPath] == YES)
	{
		// Check if installed plugin is older than app's version
		NSDictionary *oldPluginAttr = [fm fileAttributesAtPath:oldPluginPath traverseLink:NO];
		NSDictionary *newPluginAttr = [fm fileAttributesAtPath:newPluginPath traverseLink:NO];
		
		NSDate *oldPluginDate = [oldPluginAttr objectForKey: NSFileModificationDate];
		NSDate *newPluginDate = [newPluginAttr objectForKey: NSFileModificationDate];
		
		if (oldPluginDate != nil && newPluginDate != nil)
		{
			if ([newPluginDate compare: oldPluginDate] ==  NSOrderedDescending)
			{
				if ([fm removeFileAtPath: oldPluginPath handler: nil] == NO)
				{
					NSLog(@"Failed to remove old plugin at %@", oldPluginPath);
				}
				
				// Install new version of plugin
				if ([fm copyPath: newPluginPath	toPath: oldPluginPath handler:nil] == NO)
				{
					NSLog(@"Failed installing the new plugin at %@", oldPluginPath);
				}
			}
		}
		
		
	}

}


#pragma mark -
#pragma mark File Sizing Methods
// =========================================================================
// (FSRef) convertStringToFSRef: (NSString *) path
// -------------------------------------------------------------------------
// Convert NSString to FSRef
// -------------------------------------------------------------------------
// Created: 10 December 2009 22:37
// Version: 9 June 2010 21:23
// =========================================================================
- (FSRef) convertStringToFSRef: (NSString *) path
{
	// This converts an NSString path to a FSRef correctly.
	// The Dell Inspiron backup was sized properly at 20662092257, whereas the old method
	// returned the value 25893905653.  If a file name had a semi-colon in it, the entire
	// parent directory would be given as the file's size.
	FSRef output;
	
	NSURL *fileURL = [NSURL fileURLWithPath: path];

    if (!CFURLGetFSRef( (CFURLRef)fileURL, &output )) 
	{
        NSLog( @"Failed to create FSRef." );
    }	
	
	return output;
}

// =========================================================================
// (unsigned long long) fileSize: (NSString *) path
// -------------------------------------------------------------------------
// -------------------------------------------------------------------------
// Created: 10 December 2009 22:45
// Version: 21 May 2010 22:39
// =========================================================================
- (unsigned long long) fileSize: (NSString *) path
{
	unsigned long long pathFileSize = 0;
	
	if ([self isFileSymbolicLink: path] == YES)
	{
		NSDictionary *fattrs = [fm fileAttributesAtPath: path traverseLink: NO];
		
		if (fattrs != nil)
		{
			NSNumber *numFileSize;
			
			numFileSize = [fattrs objectForKey: NSFileSize];
			pathFileSize = [numFileSize unsignedLongLongValue];
		}
	}
	else
	{
		FSRef ref = [self convertStringToFSRef: path];
		pathFileSize = [self fastFolderSizeAtFSRef: &ref];
	}
	

	
	return (pathFileSize);
}


// =========================================================================
// (unsigned long long) fastFolderSizeAtFSRef:(FSRef*)theFileRef
// -------------------------------------------------------------------------
//
// =========================================================================
- (unsigned long long) fastFolderSizeAtFSRef:(FSRef*)theFileRef
{
	FSIterator	thisDirEnum = NULL;
	unsigned long long totalSize = 0;
	
	
	// Iterate the directory contents, recursing as necessary
	if (FSOpenIterator(theFileRef, kFSIterateFlat, &thisDirEnum) == noErr)
	{
		const ItemCount kMaxEntriesPerFetch = 256;
		ItemCount actualFetched;
		FSRef	fetchedRefs[kMaxEntriesPerFetch];
		FSCatalogInfo fetchedInfos[kMaxEntriesPerFetch];
		
		OSErr fsErr = FSGetCatalogInfoBulk(thisDirEnum, kMaxEntriesPerFetch, &actualFetched,
										   NULL, kFSCatInfoDataSizes | kFSCatInfoRsrcSizes | kFSCatInfoNodeFlags, fetchedInfos,
										   fetchedRefs, NULL, NULL);
		while ((fsErr == noErr) || (fsErr == errFSNoMoreItems))
		{
			ItemCount thisIndex;
			for (thisIndex = 0; thisIndex < actualFetched; thisIndex++)
			{
				// Recurse if it's a folder
				if (fetchedInfos[thisIndex].nodeFlags & kFSNodeIsDirectoryMask)
				{
					totalSize += [self fastFolderSizeAtFSRef:&fetchedRefs[thisIndex]];
				}
				else
				{
					// add the size for this item
					totalSize += fetchedInfos[thisIndex].dataLogicalSize + fetchedInfos[thisIndex].rsrcLogicalSize;
				}
			}
			
			if (fsErr == errFSNoMoreItems)
			{
				break;
			}
			else
			{
				// get more items
				fsErr = FSGetCatalogInfoBulk(thisDirEnum, kMaxEntriesPerFetch, &actualFetched,
											 NULL, kFSCatInfoDataSizes | kFSCatInfoNodeFlags, fetchedInfos,
											 fetchedRefs, NULL, NULL);
			}
		}
		FSCloseIterator(thisDirEnum);
	}
	else
	{
		FSCatalogInfo		fsInfo;

		if(FSGetCatalogInfo(theFileRef, kFSCatInfoDataSizes | kFSCatInfoRsrcSizes, &fsInfo, NULL, NULL, NULL) == noErr)
		{
			if (fsInfo.rsrcLogicalSize > 0)
			{
				totalSize += (fsInfo.dataLogicalSize + fsInfo.rsrcLogicalSize);
			}
			else
			{
				totalSize += (fsInfo.dataLogicalSize);
			}
		}
	}
	
	return totalSize;
}


// =========================================================================
// (NSString *) formatFileSize: (double) file_size
// -------------------------------------------------------------------------
// Should (double) file)_size be changed to unsigned long long?
// -------------------------------------------------------------------------
// Created: 8 August 2007 22:09
// Version: 25 May 2010
// =========================================================================
- (NSString *) formatFileSize: (double) file_size
{
	NSString *file_size_label;
	double baseSize = 1024.0;	// For Mac OS 10.6+, set this to 1000.0
	
	SInt32		systemVersion;
	Gestalt(gestaltSystemVersion, (SInt32 *) &systemVersion); 	// What version of OS X are we running?
	
	if (systemVersion >= 0x00001060)
	{
		baseSize = 1000.0;
	}
	
	if ( (file_size / baseSize) < 1.0)
		file_size_label = @" bytes";
	else if ((file_size / pow(baseSize, 2)) < 1.0)
	{
		file_size = file_size / baseSize;
		file_size_label = @" KB";
	}
	else if ((file_size / pow(baseSize, 3)) < 1.0)
	{
		file_size = file_size / pow(baseSize, 2);
		file_size_label = @" MB";
	}
	else
	{
		file_size = file_size / pow(baseSize, 3);
		file_size_label = @" GB";
	}	
	
	return ([NSString stringWithFormat: @"%.2f%@", file_size, file_size_label]);
}

#pragma mark -

// =========================================================================
// (void) addNewFiles : (NSTimer *) aTimer
// -------------------------------------------------------------------------
// Add new files to the list of files that were dragged-n-dropped on the icon
// -------------------------------------------------------------------------
// Created: 30. March 2004 23:52
// Version: 30. March 2004 23:52
// =========================================================================
- (void) addNewFiles : (NSTimer *) aTimer
{
    [aTimer invalidate];
    timer = nil;
}


// =========================================================================
// (void) erase: 
// -------------------------------------------------------------------------
// NSFileManager: http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Classes/NSFileManager_Class/Reference/Reference.html
// NSDirectoryEnumerator: http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Classes/NSDirectoryEnumerator_Class/Reference/Reference.html
// -------------------------------------------------------------------------
// Unfortunately, all of the files in the Trash couldn't be erased at once.
// This error occurred: /bin/rm: /Users/admin/.Trash/*: No such file or directory
// [pEraser setArguments: [NSArray arrayWithObjects: @"-P", @"-r", [@"~/.Trash/*" stringByExpandingTildeInPath], nil]];
// -------------------------------------------------------------------------    
// Created: 2. June 2003 14:20
// Version: 29 December 2010 20:30
// =========================================================================
- (void) erase
{
    idx = 0;
    num_files = 0;
	
    num_files = [trash_files count];
		
	// If srm already exists, use that version, which will help comply as 
	// a Universal Binary to use the PPC or Intel version of srm
	if ([fm isExecutableFileAtPath: @"/usr/bin/srm"] == YES)
	{
		util_path = @"/usr/bin/srm";
	}
	else
	{
		util_path  = [[NSBundle mainBundle] pathForResource:@"srm" ofType:@""];
	}

    [indicator setMaxValue: totalFilesSize*100];
    
	[indicator setIndeterminate: NO];
    [indicator stopAnimation: self];
	[erasing_msg setStringValue:NSLocalizedString(@"ErasingMessage", nil)];

//	NSLog(@"totalFilesSize: %llu", totalFilesSize);
	
//	NSLog(@"Files: %@", trash_files);
	
	// Throw a warning about erasing files.
	// Hold down the Option key when launching PE to prevent this warning from appearing.
	if (warnBeforeErasing == YES)
	{
//		int choice = 0;
		
		if (files_were_dropped == YES && num_files == 1)	// Erasing one files
		{
			NSAlertCheckbox *alert = [NSAlertCheckbox alertWithMessageText: NSLocalizedString(@"ErrorTitle", nil)
															 defaultButton: NSLocalizedString(@"OK", nil)
														   alternateButton: NSLocalizedString(@"Quit", nil)
															   otherButton: nil
		informativeText: [NSString stringWithFormat: NSLocalizedString(@"ErasingFileWarning", nil), [[trash_files objectAtIndex: idx] fileName]] ];
			
			//[alert setAlertStyle: NSCriticalAlertStyle];
			[alert setShowsCheckbox: YES];
			[alert setCheckboxText: NSLocalizedString(@"DoNotShowMessage", nil)];
			[alert setCheckboxState: NSOffState];

			[alert beginSheetModalForWindow: theWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
//			choice = [alert runModal];
//			
//			if ([alert checkboxState] == NSOnState)
//			{
//				[prefs setBool:NO forKey: @"WarnBeforeErasing"];
//			}			
		}
		else if (files_were_dropped == YES && num_files > 1)	// Erasing several files
		{		
			NSAlertCheckbox *alert = [NSAlertCheckbox alertWithMessageText: NSLocalizedString(@"ErrorTitle", nil)
															 defaultButton: NSLocalizedString(@"OK", nil)
														   alternateButton: NSLocalizedString(@"Quit", nil)
															   otherButton: nil
														   informativeText: NSLocalizedString(@"ErasingFilesWarning", nil)];
			
			[alert setShowsCheckbox: YES];
			[alert setCheckboxText: NSLocalizedString(@"DoNotShowMessage", nil)];
			[alert setCheckboxState: NSOffState];

			[alert beginSheetModalForWindow: theWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];			
//			choice = [alert runModal];
//			
//			if ([alert checkboxState] == NSOnState)
//			{
//				[prefs setBool:NO forKey: @"WarnBeforeErasing"];
//			}
			
		}
		else	// Erasing files from the Trash
		{
			NSAlertCheckbox *alert = [NSAlertCheckbox alertWithMessageText: NSLocalizedString(@"ErrorTitle", nil)
															 defaultButton: NSLocalizedString(@"OK", nil)
														   alternateButton: NSLocalizedString(@"Quit", nil)
															   otherButton: nil
														   informativeText: NSLocalizedString(@"ErasingTrashWarning", nil)];
			
			[alert setShowsCheckbox: YES];
			[alert setCheckboxText: NSLocalizedString(@"DoNotShowMessage", nil)];
			[alert setCheckboxState: NSOffState];
			
			[alert beginSheetModalForWindow: theWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
			
//			choice = [alert runModal];
//			
//			if ([alert checkboxState] == NSOnState)
//			{
//				[prefs setBool:NO forKey: @"WarnBeforeErasing"];
//			}
			
		}

		// This code has been moved to the alertDidEnd method
//		if (NSAlertSecondButtonReturn == choice || NSCancelButton == choice) // Quit button
//		{
//			[NSApp terminate:self];
//		}
		
	}
	else	// no warning displayed, start erasing
	{
		if (idx < num_files)
		{
			[self selectNextFile];
		}
		else  // there are no files
		{
			[self shutdownPE];
		}
	}
}


// =========================================================================
// (void) alertDidEnd: (NSAlertCheckbox *) alert returnCode: (int) returnCode contextInfo: (void *) contextInfo
// -------------------------------------------------------------------------
// Instead of using a modal alert, run as a sheet so the Preferences can
// be accessed easily.
// -------------------------------------------------------------------------
// Created: 29 December 2010 20:30
// Version: 29 December 2010 20:30
// =========================================================================
- (void) alertDidEnd: (NSAlertCheckbox *) alert returnCode: (int) returnCode contextInfo: (void *) contextInfo
{
	if ([alert checkboxState] == NSOnState)
	{
		[prefs setBool:NO forKey: @"WarnBeforeErasing"];
	}
	
	if (NSAlertSecondButtonReturn == returnCode || NSCancelButton == returnCode)	// Quit
	{
		[NSApp terminate:self];
	}
	else
	{
		if (idx < num_files)
		{
			[self selectNextFile];
		}
		else  // there are no files
		{
			[self shutdownPE];
		}
	}
}

// =========================================================================
// (void) selectNextFile
// -------------------------------------------------------------------------
// Determine whether to erase a regular file, or to burn an optical disc
// -------------------------------------------------------------------------
// Created: 6 March 2007 20:10
// Version: 29 June 2009 21:32
// =========================================================================
- (void) selectNextFile
{
	if ([[trash_files objectAtIndex: idx] isErasableDisc] == YES)
	{
		[self eraseDisc];
	}
	else
	{
		[self runTask];
	}
}


// =========================================================================
// (void) eraseDisc
// -------------------------------------------------------------------------
// http://developer.apple.com/documentation/MusicAudio/Reference/DiscRecordingFrameworkRef/DRErase/Classes/DRErase/index.html#//apple_ref/occ/cl/DRErase
// NSLog(@"IORegistryEntry: %@", [[device info] objectForKey:DRDeviceIORegistryEntryPathKey]);
// -------------------------------------------------------------------------
// Created: 28 February 2007
// Version: 6 December 2010 21:35
// =========================================================================
- (void) eraseDisc
{	
	DRDevice* device;
	DRErase* erase;	

	[progress_msg setStringValue: [self fileNameString]];
	//[progress_msg setStringValue: [[trash_files objectAtIndex: idx] fileName]];
	[fileIcon setImage: [[trash_files objectAtIndex: idx] icon]];

	device = [DRDevice deviceForBSDName: [self bsdDevNode: [[trash_files objectAtIndex: idx] path]]];	

	if (device != nil)
	{
		erase = [[DRErase alloc] initWithDevice:device];
		
		if ([discErasingLevel isEqualToString:@"Quick"])
		{
			[erase setEraseType:DREraseTypeQuick];	
		}
		else
		{
			[erase setEraseType:DREraseTypeComplete];
		}

		// register to receive notification about the erase status.	
		[[DRNotificationCenter currentRunLoopCenter] addObserver:self	
			selector:@selector(eraseNotification:)	
			name:DREraseStatusChangedNotification 
			object:erase];
		
		[cancelButton setEnabled:NO];
		[cancelMenuItem setEnabled:NO];
		isCurrentlyErasingDisc = YES;

		[erase start];
	}
	else
	{
		NSRunAlertPanel(NSLocalizedString(@"ErrorTitle",nil), NSLocalizedString(@"ErrorDeletingDiscMessage",nil), NSLocalizedString(@"OK",nil), nil, nil);
		
		// Continue on as if this was successful in erasing...
		[indicator incrementBy: [[trash_files objectAtIndex: idx] filesize] * 100.0];
		// [self updateApplicationBadge];
		[badge badgeApplicationDockIconWithProgress:([indicator doubleValue] / [indicator maxValue]) insetX:2 y:0];
		[self doneErasing:nil];
	}

} 


// =========================================================================
// (void) eraseNotification: (NSNotification*) notification
// -------------------------------------------------------------------------
// Receive notifications while the optical disc is being erased
// -------------------------------------------------------------------------
// Created: 28 February 2007
// Version: 6 December 2010 21:35
// =========================================================================
- (void) eraseNotification: (NSNotification*) notification	
{	
	// DRErase* erase = [notification object];	
	NSDictionary* status = [notification userInfo];	
	unsigned long long currentFileSize = [[trash_files objectAtIndex: idx] filesize];

	// States: DRStatusStatePreparing, DRStatusStateErasing, DRStatusStateDone, DRStatusStateFailed
	if ([[status objectForKey: DRStatusStateKey] isEqualToString: @"DRStatusStateDone"])
	{
		isCurrentlyErasingDisc = NO;
		// kick out of function, reset, clean up, and move onto the next file
		[self doneErasing: nil];
	}
	else
	{
		int currentPercentageCD = [[status objectForKey: DRStatusPercentCompleteKey] floatValue] * 100;
		
		if (currentPercentageCD < 0)
			currentPercentageCD = 0;
		else if (currentPercentageCD > 100)
			currentPercentageCD = 100;
		
		// Create an updateProgressBar method
		if (currentPercentageCD >= lastPercentageCD)
		{
			[indicator incrementBy: (currentPercentageCD - lastPercentageCD)  * currentFileSize/[[trash_files objectAtIndex: idx] numberOfFiles]];
			[self updateIndicator];
		}
		else
		{
			[indicator incrementBy: (100 - currentPercentageCD) * currentFileSize/[[trash_files objectAtIndex: idx] numberOfFiles]];
			[self updateIndicator];
		}
		
		[fileSizeMsg setStringValue: [[[self formatFileSize: ([indicator doubleValue] / [indicator maxValue]) *totalFilesSize] stringByAppendingString: NSLocalizedString(@"Of", nil)] stringByAppendingString: [self formatFileSize: (double)totalFilesSize]]];
		[badge badgeApplicationDockIconWithProgress:([indicator doubleValue] / [indicator maxValue]) insetX:2 y:0];
		
		if (currentPercentageCD >= 100)
		{
			currentPercentageCD = 0;
			lastPercentageCD = 0;
		}
		else
		{
			lastPercentageCD = currentPercentageCD;
		}
		
		// If the optical disc erasing failed...
		if ([[status objectForKey: DRStatusStateKey] isEqualToString: @"DRStatusStateFailed"])
		{
			NSRunAlertPanel(NSLocalizedString(@"ErrorTitle",nil), NSLocalizedString(@"ErrorDeletingDiscMessage",nil), NSLocalizedString(@"OK",nil), nil, nil);
			isCurrentlyErasingDisc = NO;
			[self doneErasing: nil];
		}
	
	}
	
}


// =========================================================================
// (void) runTask
// -------------------------------------------------------------------------
// Set the NSTask parameters and launch the task.  If a file is symbolic 
// link, remove it with rm, because srm will try and remove the original
// file instead of the symbolic link.
// -------------------------------------------------------------------------
// Created: 4. April 2004 23:35
// Version: 14 December 2009 22:00
// =========================================================================
- (void) runTask
{
	if (pEraser == nil)
	{
		pEraser = [[NSTask alloc] init];
	}
	
    // If the file is a symbolic/soft link
	if ([[trash_files objectAtIndex: idx] isSymbolicLink] == YES)
    {
        [pEraser setLaunchPath:@"/bin/rm"];
        [pEraser setArguments: [NSArray arrayWithObjects: @"-Pv", [[trash_files objectAtIndex: idx] path], nil] ];
    }
    else // regular file or directory
    {
        [pEraser setLaunchPath:util_path];

		if ([[prefs objectForKey: @"FileErasingLevel"] isEqualToString: NSLocalizedString(@"FileErasingSimple", nil)])
		{
			[pEraser setArguments: [NSArray arrayWithObjects: @"-fsvrz", [[trash_files objectAtIndex: idx] path], nil] ];
		}
		else if ([[prefs objectForKey: @"FileErasingLevel"] isEqualToString: NSLocalizedString(@"FileErasingMedium", nil)])
		{
			[pEraser setArguments: [NSArray arrayWithObjects: @"-fmvrz", [[trash_files objectAtIndex: idx] path], nil] ];
		}
		else	// Otherwise, use the 35-pass Gutmann Method
		{
			[pEraser setArguments: [NSArray arrayWithObjects: @"-fvrz", [[trash_files objectAtIndex: idx] path], nil] ];
		}
    }
	

	// Throw a warning if a file cannot be erased
	if (([fm isDeletableFileAtPath:[[trash_files objectAtIndex: idx] path]] == NO) || 
		([self checkPermissions: [[trash_files objectAtIndex: idx] path]] == NO)  ||
		(([[trash_files objectAtIndex: idx] isDirectory] == YES) && ([[trash_files objectAtIndex: idx] isPackage] == NO) && ([self directoryIsEmpty: [[trash_files objectAtIndex: idx] path]] == NO)))
	{
		int choice = -1; 
		
		if (suppressCannotEraseWarning == NO)
		{
			NSAlertCheckbox *alert = [NSAlertCheckbox alertWithMessageText: NSLocalizedString(@"ErrorTitle", nil)
															 defaultButton: NSLocalizedString(@"OK", nil)
														   alternateButton: NSLocalizedString(@"Quit", nil)
															   otherButton: nil
														   informativeText: [NSString stringWithFormat:@"%@\"%@\"", NSLocalizedString(@"ErrorDeletingMessage", nil), [[trash_files objectAtIndex: idx] fileName]] ];

			[alert setShowsCheckbox: YES];
			[alert setCheckboxText: NSLocalizedString(@"DoNotShowMessage", nil)];
			[alert setCheckboxState: NSOffState];
			
			choice = [alert runModal];
			
			if ([alert checkboxState] == NSOnState)
			{
				// This setting is not saved permanently and is only set on a per-session basis
				suppressCannotEraseWarning = YES;
			}
		}


		if (choice == 0) // Quit button
		{
			[[NSApplication sharedApplication] terminate:self];
		}
		else
		{
			// Act like the file was erased and move on to the next file
			[indicator incrementBy:[[trash_files objectAtIndex: idx] filesize]*100.0];
			[self updateIndicator];
			[ [NSNotificationCenter defaultCenter] postNotificationName: @"NSTaskDidTerminateNotification" object: self];
		}
		
	}	
	else
	{
     
		pipe = [[NSPipe alloc] init];
		
		[progress_msg setStringValue: [self fileNameString]];
		//[progress_msg setStringValue: [[trash_files objectAtIndex: idx] fileName]];
		if ([[trash_files objectAtIndex: idx] icon] != nil)
		{
			[fileIcon setImage: [[trash_files objectAtIndex: idx] icon]];
		}
    
		[pEraser setStandardOutput:pipe];
		[pEraser setStandardError:pipe];
		handle = [pipe fileHandleForReading];
		NSDictionary *fileAttributes = [fm fileAttributesAtPath: [[trash_files objectAtIndex: idx] path] traverseLink:NO];
		
		// If the file is locked by the Finder, unlock it before deleting.
		if ([[fileAttributes objectForKey:NSFileImmutable] boolValue] == YES)
		{
			[fm changeFileAttributes: [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:NSFileImmutable] atPath:[[trash_files objectAtIndex: idx] path]];
		}
		
		// If it is a directory or empty file, add 100 since it doesn't delete like normal files
		// Note: Might want to reconsider incrementing at all since files of 0 size normally wouldn't add anything 
		// to the progress bar...
		if (([[trash_files objectAtIndex: idx] isDirectory] == YES) && ([[trash_files objectAtIndex: idx] isPackage] == NO))
		{
			[indicator incrementBy: 100.0];
		}
		else if ([[fileAttributes objectForKey:NSFileSize] intValue] == 0) // file is 0K in size
		{
			[indicator incrementBy: 100.0];
		}
					
		[pEraser launch];
		
		[NSThread detachNewThreadSelector: @selector(outputData:) toTarget: self withObject: handle];
	}
    
}


// =========================================================================
// (void) outputData: (NSFileHandle *) current_handle
// -------------------------------------------------------------------------
// Direct the output data sent from the task to be read by the program
// -------------------------------------------------------------------------
// Created: 25 October 2005 19:14
// Version: 17 August 2011 18:16
// =========================================================================
- (void) outputData: (NSFileHandle *) current_handle
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSData *data;
	int lastPercentage = 0;
	int currentPercentage = 0;
	unsigned long long currentFileSize = [[trash_files objectAtIndex: idx] filesize];

	// Catch NSFileHandleOperationException which occurred when trying to erase symlinks
	@try 
	{
	
		while ([data=[current_handle availableData] length] && totalFilesSize != 0)
		{
			NSString *string = [[NSString alloc] initWithData:data encoding: NSASCIIStringEncoding];
			NSString *modifiedString = [[NSString alloc] initWithString: [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			
			// stringByTrimmingCharactersInSet is a 10.2+ feature. 
			NSArray *splitString = [modifiedString componentsSeparatedByString: @"%"];
			
			currentPercentage = [[splitString objectAtIndex: 0] intValue];		

			[string release];
			[modifiedString release];
			
			// If it is an application, need to keep in mind there are extra files inside, so taking the currentFileSize won't work.
			if (currentPercentage >= lastPercentage)
			{
				
				[indicator incrementBy: (currentPercentage - lastPercentage) * currentFileSize/[[trash_files objectAtIndex: idx] numberOfFiles]];
				[self updateIndicator];
			}
			else
			{
				[indicator incrementBy: (100 - currentPercentage) * currentFileSize/[[trash_files objectAtIndex: idx] numberOfFiles]];
				[self updateIndicator];
			}
			
			
			[fileSizeMsg setStringValue: [[[self formatFileSize: ([indicator doubleValue] / [indicator maxValue]) *totalFilesSize] stringByAppendingString: NSLocalizedString(@"Of", nil)] stringByAppendingString: [self formatFileSize: (double)totalFilesSize]]];
	//		[self updateApplicationBadge];
			[badge badgeApplicationDockIconWithProgress:([indicator doubleValue] / [indicator maxValue]) insetX:2 y:0];
			
			if (currentPercentage >= 100)
			{
				currentPercentage = 0;
				lastPercentage = 0;
			}
			else
			{
				lastPercentage = currentPercentage;
			}
		}
	
	}
	@catch (NSException * exception) 
	{
		NSLog(@"Exception name: %@ Reason: %@", [exception name], [exception reason]);
		// NSLog(@"Exception info: %@", [exception userInfo]);
	}
	@finally 
	{
	}
	
    [pool release];
	
	[NSThread exit];
}


// =========================================================================
// - (void) updateIndicator
// -------------------------------------------------------------------------
// Force the progress indicator to redraw itself.  This was used to correct
// an issue with older versions of Mac OS X where the indicator did not
// always redraw itself properly.  This is not done in Mac OS 10.6+, since
// it caused the program to crash when the window was minimized in Snow 
// Leopard.
// -------------------------------------------------------------------------
// Created: 29 November 2009 22:46
// Version: 29 November 2009 22:46
// =========================================================================
- (void) updateIndicator
{
	if (osVersion < 0x00001060)
	{
		[indicator displayIfNeeded];  // force indicator to draw itself
	}
}


// =========================================================================
// - (void) updateApplicationBadge
// -------------------------------------------------------------------------
// http://www.macdevcenter.com/pub/a/mac/2001/10/19/cocoa.html?page=3
// [[NSColor colorWithCalibratedRed: 0.6 green: 0.6 blue: 0.8 alpha:1.0] set]; // create a custom color
// [[[NSColor orangeColor] colorWithAlphaComponent:0.7] set];
// -------------------------------------------------------------------------
// Created: November 2005
// Version: 19 November 2006 16:27
// =========================================================================
- (void) updateApplicationBadge 
{
	NSImage *icon = [NSImage imageNamed:@"NSApplicationIcon"];
	NSRect r = NSMakeRect(90.0, 10.0, 32.0, 32.0); 
	NSRect r2 = NSMakeRect(88.0, 5.0, 36.0, 35.0);
	
	[icon lockFocus];

	// Draw the badge image

	end_angle = 90.0 - ([indicator doubleValue] / [indicator maxValue]) * 360;

	NSBezierPath *bp = [NSBezierPath bezierPathWithOvalInRect:r];	
	NSBezierPath *bp2 = [NSBezierPath bezierPath];


	if (firstTimeHere == YES)
	{
		firstTimeHere = NO;

		// Draw the shadow behind the progress badge
		NSBezierPath *bp3 = [NSBezierPath bezierPathWithOvalInRect:r2];
		[[[NSColor blackColor] colorWithAlphaComponent:0.3] set];
		[bp3 fill];

		// If the background orange and white circle is drawn only once at 
		// this point, the outside edges are smoother, but the progress
		// meter inside becomes very jagged.
	}

	// Draw the background circle (white background with an orange edge)
	[bp setLineWidth: 5.0];
	[bp setFlatness:0.1];  // This smooths the edges by a bit
	[[NSColor orangeColor] set];
	[bp stroke];
	
	[[NSColor whiteColor] set];
	[bp fill];
	

	// Draw the progress meter
	[bp2 moveToPoint:NSMakePoint(106.0, 26.0)];
	[bp2 lineToPoint:NSMakePoint(106.0, 43.0)];
	[bp2 appendBezierPathWithArcWithCenter: NSMakePoint(106.0, 26.0) radius: 17.0 startAngle: 90.0 endAngle: end_angle clockwise: YES];

	[[NSColor orangeColor] set];
	[bp2 fill];


/*	
	float size = 16.0;
	float scaleFactor = size/16;
	float stroke = 2*scaleFactor;	//native size is 16 with a stroke of 2
	float shadowBlurRadius = 1*scaleFactor;
	float shadowOffset = 1*scaleFactor;
	float shadowOpacity = .3;	
	
	[NSGraphicsContext saveGraphicsState];
		NSShadow *theShadow = [[NSShadow alloc] init];
		[theShadow setShadowOffset: NSMakeSize(0,-shadowOffset)];
		[theShadow setShadowBlurRadius:shadowBlurRadius];
		[theShadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:shadowOpacity]];
		[theShadow set];
		[theShadow release];
		[[NSColor orangeColor] set];
		[[NSBezierPath bezierPathWithOvalInRect:r] fill];
	[NSGraphicsContext restoreGraphicsState];	
	
	[[NSColor whiteColor] set];
	//NSBezierPath *slice = [NSBezierPath bezierPath];
	[bp2 moveToPoint:NSMakePoint(NSMidX(r),NSMidY(r))];
	[bp2 appendBezierPathWithArcWithCenter:NSMakePoint(NSMidX(r),NSMidY(r)) radius:NSHeight(r)/2-stroke startAngle:90 endAngle:end_angle clockwise:NO];	
//	[bp2 appendBezierPathWithArcWithCenter:NSMakePoint(NSMidX(r),NSMidY(r)) radius:NSHeight(r)/2-stroke startAngle:90 endAngle:90-progress*360 clockwise:NO];
	[bp2 moveToPoint:NSMakePoint(NSMidX(r),NSMidY(r))];
	[bp2 fill];
*/	
	
	[icon unlockFocus];
	[NSApp setApplicationIconImage:icon];
	
	// Clean up the icon before the application quits
	if (!registeredForTerminate) 
	{
		registeredForTerminate = YES;
//		[[NSNotificationCenter defaultCenter] addObserver:self 
//								selector:@selector(appWillTerminateNotification:) 
//								name:NSApplicationWillTerminateNotification 
//								object:NSApp];
	}

}


#pragma mark -
#pragma mark File Methods
// =========================================================================
// (NSString *) currentFileName
// -------------------------------------------------------------------------
// Retrieve the short version of the current file (i.e. "foo.txt") being 
// deleted (so no full path).
// -------------------------------------------------------------------------
// Created: 9 October 2005 17:30
// Version: 9 October 2005 17:30
// =========================================================================
- (NSString *) currentFileName
{
	return ([[trash_files objectAtIndex: idx] lastPathComponent]);
}


// =========================================================================
// (NSString *) fileNameString
// -------------------------------------------------------------------------
// If a file name is too long (over the length of the progress_msg field), 
// the entire string will not print properly in the text field in the 
// interface.  This checks if the file name exceeds the length limit, and
// if so, then it puts an ellipse (ellipsis) in the middle of the file name
// to abridge it.
// -------------------------------------------------------------------------
// Created: 2. April 2004 1:05
// Version: 15 September 2009 22:53
// =========================================================================
- (NSString *) fileNameString
{

    NSMutableString *current_file_name = [[NSMutableString alloc] initWithString: [[trash_files objectAtIndex: idx] fileName]];
    int cfl_length = [current_file_name length];
    float cfl_len = 0.0;
    float field_width = [progress_msg bounds].size.width;

    dict  = [ [NSMutableDictionary alloc] init];
    [dict setObject:[NSFont fontWithName:@"Lucida Grande Bold" size:11.0] forKey:NSFontAttributeName];
    cfl_len = [current_file_name sizeWithAttributes:dict].width;
    
    if (cfl_len > field_width)
    {
        [current_file_name replaceCharactersInRange: NSMakeRange(cfl_length-10, 3) withString:@"..."];
        
        while (cfl_len > field_width)
        {
            [current_file_name deleteCharactersInRange: NSMakeRange(cfl_length-11, 1)];
            cfl_length = [current_file_name length];
            cfl_len = [current_file_name sizeWithAttributes:dict].width;
        }
        
        [dict release];
        
        return (NSString *)current_file_name;
    }
    else
    {
        [dict release];
		
        return (NSString *)current_file_name;
    }
	
}


// =========================================================================
// (BOOL) checkPermissions: (NSString *)path
// -------------------------------------------------------------------------
// This bit of code is based from from tree_walker.c (lines 39-52), which is
// from the source code for srm.
// This is used to check if a file can be deleted or not.  It handles the 
// cases where the file isn't owned by the current users, which then has
// difficulty in deleting such files.
// -------------------------------------------------------------------------
// Created: 7 December 2006 19:30
// Version: 19 December 2006 22:13
// =========================================================================
- (BOOL) checkPermissions: (NSString *)path
{
	int fd;
	const char * cpath = [path UTF8String];
	
	if ( ((fd = open(cpath, O_WRONLY)) == -1) && (errno == EACCES) ) 
	{
		if ( chmod(cpath, S_IRUSR | S_IWUSR) == -1 ) 
		{
		  return (NO);
		}
	}

	close(fd);
	
	return (YES);
}


// =========================================================================
// (BOOL) containsResourceFork: (NSString *)path
// -------------------------------------------------------------------------
// Check to see if a file contains a resource fork.
// Should gather several of these file-related checks and put them into
// a separate extension class.
// -------------------------------------------------------------------------
// Created: 2 January 2007 19:49
// Version: 8 April 2007
// =========================================================================
- (BOOL) containsResourceFork: (NSString *)path 
{
	FSRef           fsRef;
	FSCatalogInfo   fsInfo;
	BOOL			isDir;

	// If path is a directory, automatically return NO
	if ( [fm fileExistsAtPath: path isDirectory:&isDir] && isDir )
	{
		return (NO);
	}
	else if(FSPathMakeRef((unsigned char *) [path fileSystemRepresentation], &fsRef, NULL) == noErr) 
	{
		if(FSGetCatalogInfo(&fsRef, kFSCatInfoRsrcSizes, &fsInfo, NULL, NULL, NULL) == noErr)
		{
			if (fsInfo.rsrcLogicalSize > 0)
			{
				return (YES);
			}
			else
			{
				return (NO);
			}
		}
	}
	   
	return (NO);
}


// =========================================================================
// (BOOL) isFileSymbolicLink: (NSString *)path
// -------------------------------------------------------------------------
// Check to see if a file is a symbolic/soft link, so the link
// can be deleted with rm instead of srm, so the original file is not 
// accidentally erased.
// -------------------------------------------------------------------------
// Version: 19. November 2004 21:28
// Created: 19. November 2004 21:28
// =========================================================================
- (BOOL) isFileSymbolicLink: (NSString *)path
{
    NSDictionary *fattrs = [fm fileAttributesAtPath: path traverseLink:NO];

    if ( [[fattrs objectForKey:NSFileType] isEqual: @"NSFileTypeSymbolicLink"])
    {
//		NSLog(@"%@ is a symbolic link", path);
        return (YES);
    }
    else
    {
        return (NO);
    }

}


// =========================================================================
// (BOOL) isVolume: (NSString *) volumePath
// -------------------------------------------------------------------------
// Check to see if the current "file" is a mounted volume (CD, HD, etc.)
// -------------------------------------------------------------------------
// Created: 3 December 2005 21:15
// Version: 3 December 2005 21:15
// =========================================================================
- (BOOL) isVolume: (NSString *) volumePath
{
	BOOL isPathVolume = NO;
	NSArray * volumesList = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
	
	if ([volumesList containsObject:volumePath] == YES)
	{
		isPathVolume = YES;
	}
	else
	{
		isPathVolume = NO;
	}
	
	return (isPathVolume);
}


// =========================================================================
// (BOOL) isErasableDisc: (NSString *) volumePath
// -------------------------------------------------------------------------
// Check to see if the current "file" is erasable optical media (CD/DVD-RW)
// -------------------------------------------------------------------------
// Created: 9 March 2007 23:12
// Version: 9 March 2007 23:12
// =========================================================================
- (BOOL) isErasableDisc: (NSString *) volumePath
{
	// detect DRDevice and then check with mediaIsErasable or DRDeviceMediaIsErasableKey
	if ([self isVolume:volumePath] == YES)
	{
		DRDevice *device;
		
		// Determine if the media can be erased...
		device = [DRDevice deviceForBSDName: [self bsdDevNode: volumePath]];
		
		if (device != nil)
		{		
			if ([device mediaIsErasable] == YES)
			{	
				return (YES);
			}
			else
			{
				return (NO);
			}
		}
		else
		{
			return (NO);
		}
	}
	else
	{
		return (NO);
	}

}


// =========================================================================
// (NSString *) volumeType: (NSString *) volumePath
// -------------------------------------------------------------------------
// Portions of this code by Tjark Derlien and the CocoaTechFoundation 
// framework
// (BOOL)getInfoForFile:(NSString *)fullPath application:(NSString **) 
// appName type:(NSString **)type
// -------------------------------------------------------------------------
// Created: 4 December 2005 14:17
// Version: 4 December 2005 14:17
// =========================================================================
- (NSString *) volumeType: (NSString *) volumePath
{
	struct statfs stat;
	
	if (statfs([volumePath fileSystemRepresentation], &stat) == 0)
	{
		NSString *fileSystemName = [fm stringWithFileSystemRepresentation: stat.f_fstypename length: strlen(stat.f_fstypename)];
		
		if ([fileSystemName isEqualToString:@"hfs"])
			return (fileSystemName);	//HFS(+)
		else if ([fileSystemName isEqualToString:@"nfs"])
			return (fileSystemName);	//NFS (may also be FTP)
		else if ([fileSystemName isEqualToString:@"ufs"])
			return (fileSystemName);	//UFS
		else if ([fileSystemName isEqualToString:@"msdos"])
			return (fileSystemName);	//FAT (USB stick?)
		else if ([fileSystemName isEqualToString:@"afpfs"])
			return (fileSystemName);	//Apple Share
		else if ([fileSystemName isEqualToString:@"webdav"])
			return (fileSystemName);	//WebDAV
		else if ([fileSystemName isEqualToString:@"cddafs"])
			return (fileSystemName);	//audio CD
		else if ([fileSystemName isEqualToString:@"smbfs"])
			return (fileSystemName);	//SMB (Samba/Windows share)
		else if ([fileSystemName isEqualToString:@"cifs"])
			return (fileSystemName);	//CIFS (Windows share)
		else if ([fileSystemName isEqualToString:@"cd9660"])
			return (fileSystemName);	//data CD
		else if ([fileSystemName isEqualToString:@"udf"])
			return (fileSystemName);	//UDF (DVD)
		else if ([fileSystemName isEqualToString:@"ncp"])
			return (fileSystemName);	//Novell netware
		else
			return (@"");	// return an empty string
	}
	else
	{
		return (@"");
	}
}


// =========================================================================
// (NSString *) bsdDevNode: (NSString *) volumePath
// -------------------------------------------------------------------------
// Return the "parent" BSD node name of a CD-RW/DVD-RW.  If the BSD name
// is "/dev/disk3s1s2", this method will return "disk3"
// Here's another interesting bit of code, that wasn't used, but somewhat
// similar idea to what was done in this method.
// http://snipplr.com/view/1645/given-a-mount-path-retrieve-a-usb-device-name/
// -------------------------------------------------------------------------
// Created: 1 March 2007 21:16
// Version: 17 August 2011 18:06
// =========================================================================
- (NSString *) bsdDevNode: (NSString *) volumePath
{
	struct statfs devStats;
	
	statfs([volumePath UTF8String], &devStats);
	
	NSString *bsdNodePath = [[[NSString alloc] initWithUTF8String:devStats.f_mntfromname] autorelease];
	
	return ([[bsdNodePath lastPathComponent] substringToIndex:5]);
}


// =========================================================================
// (NSString *) directoryIsEmpty: (NSString *) path
// -------------------------------------------------------------------------
// 
// -------------------------------------------------------------------------
// Created: 27 November 2009 23:35
// Version: 27 November 2009 23:35
// =========================================================================
- (BOOL) directoryIsEmpty: (NSString *) path
{
	NSArray *dirContents = [fm subpathsAtPath: path];
	
	if (dirContents != nil && [dirContents count] == 0)
	{
		return (YES);
	}
	else 
	{
		return (NO);
	}

}


#pragma mark -
#pragma mark Shutdown methods
// =========================================================================
// (void) doneErasing: (NSNotification *)aNotification
// -------------------------------------------------------------------------
// When a file is deleted, a notification is called which brings up this
// function.  If there are still files left to process in trash_files, 
// recursively run through the remainder 
// -------------------------------------------------------------------------
// Created: 2. June 2003 14:20
// Version: 14 December 2009 22:00
// =========================================================================
- (void) doneErasing: (NSNotification *)aNotification 
{
    idx++; // increment the counter here to prevent out of bound array errors

    if (idx >= num_files)  // Jobs are complete.  Quit the app.
    {
        if (files_were_dropped == NO)
        {
            // Update the Trash icon to be empty.  This doesn't work in Mac OS 10.1.
            [[NSWorkspace sharedWorkspace] noteFileSystemChanged:[@"~/.Trash/" stringByExpandingTildeInPath]];
            
            // Update .Trashes
            BOOL isDir;
            int j = 0;
            NSMutableString *currentDirectory = [[NSMutableString alloc] init];
            NSArray *volumes = [[NSArray alloc] initWithArray: [fm directoryContentsAtPath: @"/Volumes"]];  // Can also try mountedLocalVolumePaths

            for (j = 0; j < [volumes count]; j++)
            {
                // Check to see if the .Trashes exist, and if so, get the contents
                // of the .Trashes and add them to trash_files (full path)
                [currentDirectory setString: [[[@"/Volumes/" stringByAppendingPathComponent: [volumes objectAtIndex: j]]  
                                            stringByAppendingPathComponent: @".Trashes"]
                                            stringByAppendingPathComponent: uid]];
                                            
                if ( [fm fileExistsAtPath: currentDirectory isDirectory:&isDir] && isDir )
                {
                    [[NSWorkspace sharedWorkspace] noteFileSystemChanged: currentDirectory];
                }
                
            }
        
            [currentDirectory release];
            [volumes release];
        
        }
        
        [self shutdownPE];
    }
    else
    {
		if ([aNotification object] == nil)	// Sent after erasing an optical disc
		{
			[cancelButton setEnabled:YES];
			[cancelMenuItem setEnabled:YES];
		}
		else
		{
			if (handle != nil)
			{
				[handle closeFile];
				handle = nil;
			}
			
			if (pipe != nil)
			{
				[pipe release];
				pipe = nil;
			}
			
			if (pEraser != nil)
			{
				[pEraser release];
				pEraser = nil;
			}

        }
		
        [self selectNextFile];
    }

}


// =========================================================================
// (IBAction) cancelErasing: (id) sender
// -------------------------------------------------------------------------
// This is called when the Cancel button (or ESC key) is pressed.
// -------------------------------------------------------------------------
// Created: 10. October 2003 1:32
// Version: 28 October 2008 22:28
// =========================================================================
- (IBAction) cancelErasing: (id) sender
{
    idx = num_files;
	wasCanceled = YES;
    [pEraser terminate];
}



// =========================================================================
// (void) sound: (NSSound *) sound didFinishPlaying: (BOOL) aBool
// -------------------------------------------------------------------------
// 
// -------------------------------------------------------------------------
// Created: 8 December 2007 18:35
// Version: 8 December 2007 18:35
// =========================================================================
- (void) sound: (NSSound *) sound didFinishPlaying: (BOOL) aBool
{
	[NSApp terminate: self];
}


// =========================================================================
// (void) shutdownPE
// -------------------------------------------------------------------------
// Unified method when to wrap the program up and close it.
// -------------------------------------------------------------------------
// Created: 20 April 2005 20:30
// Version: 14 December 2009 22:00
// =========================================================================
- (void) shutdownPE
{
    // Completely fill the progress bar, in case of any odd inaccuracies
	// Mac OS 10.2 sometimes has problems completely filling the bar at times,
	// but do not fill it completely if erasing was canceled.
	if (([indicator doubleValue] < [indicator maxValue]) && wasCanceled == NO)
	{
		[indicator incrementBy: [indicator maxValue] - [indicator doubleValue]];
		[self updateIndicator];
	}
	
	if (beepBeforeTerminating == YES)
	{
		// If there are no files to erase, give the warning 'funk' sound
		if ( idx == 0 && [fm fileExistsAtPath: @"/System/Library/Sounds/Funk.aiff"] == YES ) 
		{
			NSSound *emptySound = [[[NSSound alloc] initWithContentsOfFile: @"/System/Library/Sounds/Funk.aiff" byReference: YES] autorelease];
			[emptySound setDelegate:self];
			[emptySound play];
		}
		// For Mac OS 10.7 Lion
		else if ( [fm fileExistsAtPath: @"/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/finder/empty trash.aif"] == YES )
		{
			NSSound *emptyTrashSound = [[[NSSound alloc] initWithContentsOfFile: @"/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/finder/empty trash.aif" byReference: YES] autorelease];
			[emptyTrashSound setDelegate:self];
			[emptyTrashSound play];
		}
		// Pre-Lion Empty Trash sound location
		else if ( [fm fileExistsAtPath: @"/System/Library/Components/CoreAudio.component/Contents/Resources/SystemSounds/finder/empty trash.aif"] == YES )
		{
			NSSound *emptyTrashSound = [[[NSSound alloc] initWithContentsOfFile: @"/System/Library/Components/CoreAudio.component/Contents/Resources/SystemSounds/finder/empty trash.aif" byReference: YES] autorelease];
			[emptyTrashSound setDelegate:self];
			[emptyTrashSound play];
		}
		else
		{
			NSBeep();
			sleep(1);  // Pause long enough for the sound to complete
			[NSApp terminate: self];
		}
	}
	else
	{
		[NSApp terminate: self];
	}
	
}


#pragma mark -
#pragma mark General menu methods
// =========================================================================
// (IBAction) openPreferencePane: (id) sender
// -------------------------------------------------------------------------
// Open the PE preference pane in the System Preferences
// Not used currently, will be necessary later...
// -------------------------------------------------------------------------
// Created: 10 July 2007 22:28
// Version: 10 July 2007 22:28
// =========================================================================
- (IBAction) openPreferencePane: (id) sender
{
	// ~/Library/PreferencePanes/Permanent Eraser.prefPane
//	[[NSWorkspace sharedWorkspace] openFile: [@"~/Library/PreferencePanes/Permanent Eraser.prefPane" stringByExpandingTildeInPath]];
	// /Library/PreferencePanes/Permanent Eraser.prefPane
	// Otherwise, throw warning that a Pref window can't be opened or found
}


// =========================================================================
// (IBAction) openPreferences: (id) sender
// -------------------------------------------------------------------------
// Show the Preferences window
// -------------------------------------------------------------------------
// Created: 13 June 2010 14:18
// Version: 30 December 2010 13:11
// =========================================================================
- (IBAction) openPreferences: (id) sender
{
	// What if a disc is getting erased, then the NSTask isn't being used...
	if (pEraser != nil)
	{
		if ([pEraser isRunning] == YES)
		{
			BOOL suspendResult = [pEraser suspend]; // returns YES if successful
			
			if (NO == suspendResult)
			{
				// error: wasn't able to suspend the task
				NSLog(@"Error suspending erasing task.");
			} 
			else
			{
				[PreferencesController sharedWindowController];
			}
		}
	}
	else if (isCurrentlyErasingDisc == YES)
	{
		[PreferencesController sharedWindowController];
	}
	else
	{
		[PreferencesController sharedWindowController];
	}
}


// =========================================================================
// - (void) preferencesClosed
// -------------------------------------------------------------------------
// Called after Preferences window closes
// -------------------------------------------------------------------------
// Created: 16 July 2010 21:36
// Version: 11 January 2011 15:40
// =========================================================================
- (void) preferencesClosed
{
	// If the NSTask was paused, tell it to resume
	if ([pEraser isRunning] == YES)
	{
		BOOL resumeResult = [pEraser resume];
		
		if (NO == resumeResult)
		{	// Error resuming NSTask
		}
	}

	
	prefs = [[NSUserDefaults standardUserDefaults] retain];
	
	if ([prefs objectForKey:@"BeepBeforeTerminating"] != nil)
	{
		beepBeforeTerminating = [prefs boolForKey:@"BeepBeforeTerminating"];
	}
	else
	{
		beepBeforeTerminating = YES;
	}
	
	if ([prefs objectForKey: @"OpticalDiscErasingLevel"] != nil)
	{
		// discErasingLevel = [[NSMutableString alloc] initWithString:[prefs objectForKey: @"OpticalDiscErasingLevel"]];
		[discErasingLevel setString: [prefs objectForKey: @"OpticalDiscErasingLevel"]];
	}
	else
	{
		discErasingLevel = [[NSMutableString alloc] initWithString:@"Complete"];
	}
	
	if ([prefs objectForKey: @"FileErasingLevel"] != nil)
	{
		// fileErasingLevel = [[NSMutableString alloc] initWithString:[prefs objectForKey: @"FileErasingLevel"]];
		[fileErasingLevel setString: [prefs objectForKey: @"FileErasingLevel"]];
	}
	else
	{
		// Assign a default fileErasingLevel
	}

}

// =========================================================================
// (IBAction) goToProductPage: (id) sender
// -------------------------------------------------------------------------
// Created: 30 December 2007 22:31
// Version: 30 December 2007 22:31
// -------------------------------------------------------------------------
// Open a web browser to go to the product web page
// =========================================================================
- (IBAction) goToProductPage: (id) sender
{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://www.edenwaith.com/products/permanent%20eraser/"]];
}


// =========================================================================
// (IBAction) sendFeedback: (id) sender
// -------------------------------------------------------------------------
// Created: 30 December 2007 22:31
// Version: 30 December 2007 22:31
// -------------------------------------------------------------------------
// Open a web browser to go to the product feedback web page
// =========================================================================
- (IBAction) sendFeedback: (id) sender
{
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"mailto:support@edenwaith.com?subject=Permanent%20Eraser%20Feedback"]];
}




@end
