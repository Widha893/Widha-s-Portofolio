# 🔬 FreeRTOS Mutex and Semaphore Example: Shared Resource and Priority Inversion
This project is a demonstration of the priority inversion problem and how FreeRTOS mutex automatically solves it using priority inheritance.

The code creates three tasks with different priorities (High, Medium, Low) that compete for the CPU. The High and Low priority tasks also compete for a single shared resource (a counter), which is protected by a mutex.

## 🏁 The Scenario

This project sets up a specific "trap" to show the problem:
1. Task H (High Priority - 3): Periodically wakes up (every 500ms), takes the mutex, increments a shared counter, and releases the mutex.
2. Task M (Medium Priority - 2): Runs very frequently (every 100ms) and just prints to the Serial monitor. It does not need the mutex.
3. Task L (Low Priority - 1): Periodically wakes up (every 400ms), takes the mutex, increments the shared counter, and releases the mutex.

The "Trap": When the shared counter hits a multiple of 10, the tasks (H or L) will call a blink...() function while holding the mutex. These blink functions use delay(), which simulates a long-running, blocking operation inside a critical section.

This creates the perfect conditions for Priority Inversion:
1. Task L (Low) takes the mutex and starts its long blinkTwice() (approx. 600ms).
2. Task H (High) wakes up (its period is 500ms) and tries to take the mutex. It Blocks (sleeps) because Task L has it.
3. The scheduler must now pick the highest-priority Ready task.
    - Task H is Blocked.
    - Task M is Ready (Prio 2).
    - Task L is Ready (Prio 1).
4. Without a Mutex: The scheduler would pick Task M, which would run indefinitely, starving Task L. This would prevent Task L from ever releasing the mutex, meaning Task H would be starved as well. This is the Priority Inversion bug.

## 🚀 How to Use

1. Upload the code.
2. Open the Serial Monitor at 115200 baud to observe the output.

## 📈 What to Expect (The Solution)

You are running code that uses xSemaphoreCreateMutex() which has Priority Inheritance built-in. Watch the Serial Monitor for this exact sequence:
1. You will see messages from all three tasks printing normally.
```bash
MEDIUM priority task is running.
HIGH priority task updated sharedResource to: 1
MEDIUM priority task is running.
LOW priority task updated sharedResource to: 2
...
```
2. When the counter (sharedResource) reaches 10, Task L will take the mutex and call blinkTwice(). The LED on your board will blink twice.
3. **This is the key moment:** Task H will wake up and try to take the mutex, but it will block.
4. **Observe the Serial Monitor:** The "MEDIUM priority task is running." messages will STOP printing.

Why? This is Priority Inheritance in action. The moment Task H (Prio 3) started waiting for the mutex held by Task L (Prio 1), the scheduler temporarily boosted Task L's priority to 3.

Now, Task L (running at Prio 3) has a higher priority than Task M (Prio 2). Task M is prevented from running, allowing Task L to finish its critical section (the blinking) as fast as possible.

As soon as Task L releases the mutex:
- Its priority instantly drops back to 1.
- Task H is unblocked, gets the mutex, and runs.
- Once Task H is done, Task M is finally allowed to run again.

The system remains responsive, and your high-priority task is only delayed by the absolute minimum time necessary.

## 💥 Challenge: See the Bug

Want to see the Priority Inversion bug in action? Make these two small changes in setup():
1. Change:
```bash
xGoodMutex = xSemaphoreCreateMutex();
```
To:
```bash
xGoodMutex = xSemaphoreCreateBinary();
```
2. Add this line right after it (binary semaphores must be "given" before they can be "taken"):
```bash
xSemaphoreGive(xGoodMutex);
```

Now, upload the code. When Task L starts blinking, you will see the "MEDIUM priority task is running." messages continue to print, flooding the console. Task L will be starved, and Task H will be stuck waiting for Task L indefinitely. You have successfully recreated the bug!