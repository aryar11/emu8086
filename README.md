# 8086 Assembly Projects

This repo contains two assembly programs developed for the 8086 processor. This project was intended for me to explore x86 assembly on a simple processor to grasp a better understanding of hardware and user input with low-level programming

---

## Programs

### Calculator

This program provides basic arithmetic operations:

* **Addition**
* **Subtraction**
* **Multiplication**
* **Division (with decimal support)**
* **Exponentiation**

It accepts two 16-bit integer inputs and an operation from the user, then outputs the result. 

### Mouse Tracker

The Mouse Tracker program displays real-time mouse coordinates within the terminal. The coordinates are updated as the cursor moves. The program also includes handling for no mouse and a clear exit condition by holding down the right mouse button

---

## Setup & Usage

These programs are intended to run using the **emu8086** emulator.

### Emulator Download

Download and install emu8086 suitable for your system from the link below:

* [emu8086 Emulator](https://emu8086.en.lo4d.com/)

### Running the Programs

1. Open your `.asm` files in the emulator.
2. Compile and run directly from emu8086.

---

## File Structure

* `calculator.asm`: Assembly source for the calculator program.
* `mouseTracker.asm`: Assembly source for the mouse tracker program.
