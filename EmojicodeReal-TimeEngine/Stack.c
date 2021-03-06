//
//  Stack.c
//  Emojicode
//
//  Created by Theo Weidmann on 02.08.15.
//  Copyright (c) 2015 Theo Weidmann. All rights reserved.
//

#include "Emojicode.h"
#include <string.h>

Thread* allocateThread() {
#define stackSize (sizeof(StackFrame) + 4 * sizeof(Something)) * 10000 //ca. 400 KB
    Thread *thread = malloc(sizeof(Thread));
    thread->stackLimit = malloc(stackSize);
    thread->returned = false;
    if (!thread->stackLimit) {
        error("Could not allocate stack!");
    }
    thread->futureStack = thread->stack = thread->stackBottom = thread->stackLimit + stackSize - 1;
    return thread;
}

Something* stackReserveFrame(void *this, uint8_t variableCount, Thread *thread){
    StackFrame *sf = (StackFrame *)(thread->futureStack - (sizeof(StackFrame) + sizeof(Something) * variableCount));
    if ((Byte *)sf < thread->stackLimit) {
        error("Your program triggerd a stack overflow!");
    }
    
    memset((Byte *)sf + sizeof(StackFrame), 0, sizeof(Something) * variableCount);
    
    sf->this = this;
    sf->variableCount = variableCount;
    sf->returnPointer = thread->stack;
    sf->returnFutureStack = thread->futureStack;
    
    thread->futureStack = (Byte *)sf;
    
    return (Something *)(((Byte *)sf) + sizeof(StackFrame));
}

void stackPushReservedFrame(Thread *thread){
    thread->stack = thread->futureStack;
}

void stackPush(void *this, uint8_t variableCount, uint8_t argCount, Thread *thread){
    Something *t = stackReserveFrame(this, variableCount, thread);
    
    for (uint8_t i = 0; i < argCount; i++) {
        t[i] = parse(consumeCoin(thread), thread);
    }
    
    stackPushReservedFrame(thread);
}

void stackPop(Thread *thread){
    thread->futureStack = ((StackFrame *)thread->stack)->returnFutureStack;
    thread->stack = ((StackFrame *)thread->stack)->returnPointer;
}

Something stackGetVariable(uint8_t index, Thread *thread){
    return *(Something *)(thread->stack + sizeof(StackFrame) + sizeof(Something) * index);
}

void stackDecrementVariable(uint8_t index, Thread *thread){
    ((Something *)(thread->stack + sizeof(StackFrame) + sizeof(Something) * index))->raw--;
}

void stackIncrementVariable(uint8_t index, Thread *thread){
    ((Something *)(thread->stack + sizeof(StackFrame) + sizeof(Something) * index))->raw++;
}

void stackSetVariable(uint8_t index, Something value, Thread *thread){
    Something *v = (Something *)(thread->stack + sizeof(StackFrame) + sizeof(Something) * index);
    *v = value;
}

Object* stackGetThis(Thread *thread){
    return ((StackFrame *)thread->stack)->this;
}

Class* stackGetThisClass(Thread *thread){
    return ((StackFrame *)thread->stack)->thisClass;
}

void stackMark(Thread *thread){
    for (StackFrame *stackFrame = (StackFrame *)thread->futureStack; (Byte *)stackFrame < thread->stackBottom; stackFrame = stackFrame->returnFutureStack) {
        for (uint8_t i = 0; i < stackFrame->variableCount; i++) {
            Something *s = (Something *)(((Byte *)stackFrame) + sizeof(StackFrame) + sizeof(Something) * i);
            if (isRealObject(*s)) {
                mark(&s->object);
            }
        }
        if (isPossibleObjectPointer(stackFrame->this)) {
            mark(&stackFrame->this);
        }
    }
}