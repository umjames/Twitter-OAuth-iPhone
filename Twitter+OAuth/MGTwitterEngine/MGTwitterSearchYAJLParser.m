//
//  MGTwitterSearchYAJLParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 11/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterSearchYAJLParser.h"

#define DEBUG_PARSING 0

@interface MGTwitterSearchYAJLParser ()

- (BOOL)_MJ_ensureParentOfStackElementIsDictionary: (MJStackElement*)stackElement;

@end

@implementation MGTwitterSearchYAJLParser

/*
 JSON parsing logic
 
 when you see the beginning of an array, dictionary or map key:
 1. create a stack element whose value is an empty mutable array, dictionary, or the map key
 2. set the stack element's parent to the top element of the stack (if the stack is empty, this is the root element)
 3. push the element onto the stack
 
 when you see a null, boolean, string, or number:
 1. look at the top element of the stack
 2. if it's an array, add the value to the array
 3. else if it's a string (map key), get the top element's parent (should be a dictionary), add the value to the dictionary using the map key as the key, and pop the top element (the map key)
 
 when you see the end of an array or dictionary:
 1. get the top element of the stack and its parent
 2. if the parent is an array, add the top element (array or dictionary) to the array and pop the top element
 3. if the parent is a string (map key), get the parent's parent (should be a dictionary), add the top element array or dictionary to the parent's parent dictionary under the map key, and pop the top 2 elements (the "value" and the map key)
 4. if the parent is nil, then pop the final top element (should be a dictionary) and end parsing
*/

- (BOOL)_MJ_ensureParentOfStackElementIsDictionary: (MJStackElement*)stackElement
{
	MJStackElement* stackElementParent = stackElement.parent;
	
	if (nil == stackElementParent)
	{
#if DEBUG_PARSING
		NSLog(@"stack element's parent is nil! parser stack = %@", _parserStack);
#endif
		return NO;
	}
	else if ([stackElementParent.value isKindOfClass: [NSMutableDictionary class]] == NO)
	{
#if DEBUG_PARSING
		NSLog(@"stack element's parent is not a dictionary! parser stack = %@", _parserStack);
#endif
		return NO;
	}
	
	return YES;
}

- (NSString*)currentKey
{
	MJStackElement*	topElem = [_parserStack findTopmostStackElementWithValueOfClass: [NSString class]];

	if (nil != topElem)
	{
		return (NSString*)topElem.value;
	}

	return nil;
}

- (void)addValue:(id)value forKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"search:  %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
#endif
	
	MJStackElement* topElement = (MJStackElement*)[_parserStack top];
	
	if ([topElement.value isKindOfClass: [NSMutableArray class]] == YES)
	{
		[topElement.value addObject: value];
	}
	else if ([topElement.value isKindOfClass: [NSString class]] == YES)
	{
		MJStackElement* topElementParent = topElement.parent;
		
		if (NO == [self _MJ_ensureParentOfStackElementIsDictionary: topElement])
		{
			return;
		}
		
		[topElementParent.value setObject: value forKey: topElement.value];
		[_parserStack pop];
	}
	else
	{
#if DEBUG_PARSING
		NSLog(@"top element is not an array or dictionary key! parser stack = %@", _parserStack);
#endif
	}
	
	//if (_results)
	{
		//[_results setObject:value forKey:key];
//#if DEBUG_PARSING
//		NSLog(@"search:   results: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
//#endif
	}
	//else if (_status)
	{
		//[_status setObject:value forKey:key];
//#if DEBUG_PARSING
//		NSLog(@"search:   status: %@ = %@ (%@)", key, value, NSStringFromClass([value class]));
//#endif
	}
}

- (void)startDictionaryWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"search: dictionary start = %@", key);
#endif

	NSMutableDictionary*	dict = [NSMutableDictionary dictionaryWithCapacity: 0];
	
	MJStackElement*			stackElement = [MJStackElement stackElementWithValue: dict parent: [_parserStack top]];
	
	[_parserStack push: stackElement];
	
	//if (insideArray)
	{
		//if (! _results)
		{
			//_results = [[NSMutableDictionary alloc] initWithCapacity:0];
		}
	}
	//else
	{
		//if (! _status)
		{
			//_status = [[NSMutableDictionary alloc] initWithCapacity:0];
		}
	}
}

- (void)endDictionary
{
	MJStackElement*	topElement = nil;
	MJStackElement* topElementParent = nil;
	
	topElement = [_parserStack top];
	topElementParent = topElement.parent;
	
	// top element should be a dictionary
	
	// see if it's key is the root results key
	MJStackElement*	resultsKeyElement = [_parserStack findTopmostStackElementWithValueOfClass: [NSString class]];
	
	if (YES == [topElement.value isKindOfClass: [NSMutableDictionary class]] 
		&& nil != resultsKeyElement 
		&& [resultsKeyElement.value isEqual: @"results"] == YES
		&& nil == resultsKeyElement.parent.parent)
	{
		[topElement.value setObject: [NSNumber numberWithInt: requestType] forKey: TWITTER_SOURCE_REQUEST_TYPE];
		[parsedObjects addObject: topElement.value];
	}
	
	if ([topElementParent.value isKindOfClass: [NSMutableArray class]] == YES)
	{
		[topElementParent.value addObject: topElement.value];
		[_parserStack pop];
	}
	else if ([topElementParent.value isKindOfClass: [NSString class]] == YES)
	{
		MJStackElement*	topElementParentParent = topElementParent.parent;
		
		if (NO == [self _MJ_ensureParentOfStackElementIsDictionary: topElementParent])
		{
			return;
		}
		
		[topElementParentParent.value setObject: topElement.value forKey: topElementParent.value];
		[_parserStack pop];
		[_parserStack pop];
	}
	else if (nil == topElementParent)
	{
		// should be done parsing here
		[_parserStack pop];
	}
	else
	{
#if DEBUG_PARSING
		NSLog(@"at the end of an array, the top element's parent is not an array or dictionary key! parser stack = %@", _parserStack);
#endif
	}	
	
	//if (insideArray)
	{
		//if (_results)
		{
			//[_results setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];
				
			//[self _parsedObject:_results];
		
			//[parsedObjects addObject:_results];
			//[_results release];
			//_results = nil;
		}
	}
	//else
	{
		//if (_status)
		{
			//[_status setObject:[NSNumber numberWithInt:requestType] forKey:TWITTER_SOURCE_REQUEST_TYPE];
				
			//[parsedObjects addObject:_status];
			//[_status release];
			//_status = nil;
		}
	}
	
#if DEBUG_PARSING
	NSLog(@"search: dictionary end");
#endif
}

- (void)startArrayWithKey:(NSString *)key
{
#if DEBUG_PARSING
	NSLog(@"search: array start = %@", key);
#endif
//	insideArray = YES;
	
	NSMutableArray*	array = [NSMutableArray arrayWithCapacity: 0];
	
	MJStackElement*	stackElement = [MJStackElement stackElementWithValue: array parent: [_parserStack top]];
	
	[_parserStack push: stackElement];
}

- (void)endArray
{
#if DEBUG_PARSING
	NSLog(@"search: array end");
#endif
//	insideArray = NO;
	MJStackElement*	topElement = nil;
	MJStackElement* topElementParent = nil;
	
	topElement = (MJStackElement*)[_parserStack top];
	topElementParent = topElement.parent;
	
	if ([topElementParent.value isKindOfClass: [NSMutableArray class]] == YES)
	{
		[topElementParent.value addObject: topElement.value];
		[_parserStack pop];
	}
	else if ([topElementParent.value isKindOfClass: [NSString class]] == YES)
	{
		MJStackElement*	topElementParentParent = topElementParent.parent;
		
		if (NO == [self _MJ_ensureParentOfStackElementIsDictionary: topElementParent])
		{
			return;
		}
		
		[topElementParentParent.value setObject: topElement.value forKey: topElementParent.value];
		[_parserStack pop];
		[_parserStack pop];
	}
	else
	{
#if DEBUG_PARSING
		NSLog(@"at the end of an array, the top element's parent is not an array or dictionary key! parser stack = %@", _parserStack);
#endif
	}
}

- (void)dictionaryKeyChanged: (NSString*)key
{
#if DEBUG_PARSING
	NSLog(@"search: dictionary key = %@", key);
#endif
	
	NSString*	keyCopy = [key copy];
	
	MJStackElement*	stackElement = [MJStackElement stackElementWithValue: keyCopy parent: [_parserStack top]];
	
	[keyCopy release];
	
	[_parserStack push: stackElement];
}

- (void)dealloc
{
//	[_results release];
//	[_status release];

	[super dealloc];
}


@end
