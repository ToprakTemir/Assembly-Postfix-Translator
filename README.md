# Postfix Translator in GNU Assembly
This project takes a line of postfix expression and input and outputs the RISC-V 32-bit machine code instructions that would be run to execute the expression in GNU Assembly

* Run the following commands to compile and run the program. 
```
make
./postfix_translator
```

* Run the following commands check a single test case.
```
python3 test/checker.py checker.py <executable> <input_file> <output_file> <expected_output_file>
```
