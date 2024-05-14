import os, sys
from subprocess import Popen, PIPE

class CustomError(Exception):
    def __init__(self, message):
        self.message = f"\033[91;1;4m{message}:\033[0m"
        super().__init__(self.message)


def check_output(output_file_name: str, expected_output_file_name: str) -> float:
    
    output_file = open(output_file_name, 'r')
    expected_output_file = open(expected_output_file_name, 'r')

    output = output_file.read().strip().split('\n')
    expected_output = expected_output_file.read().strip().split('\n')

    output = [line for line in output if line.strip()]
    expected_output = [line for line in expected_output if line.strip()]

    sum=0
    
    for i in range(min(len(output), len(expected_output))):
        if output[i]== expected_output[i]:
            sum+=1


    return sum/len(expected_output)

def run(executable: str, input_file_name: str, output_file_name: str, expected_output_file_name: str) -> float:
    
    input_file = open(input_file_name, 'r')
    output_file = open(output_file_name, 'w')

    process = Popen([f'./{executable}'], stdout=PIPE, stdin=PIPE, universal_newlines=True)

    
    process.stdin.write(input_file.readline().replace('\n', '') + '\n')
    process.stdin.flush()

    for line in process.stdout.readlines():
        output_file.write(line)

    input_file.close()
    output_file.close()
    process.stdin.close()
    process.stdout.close()

    return check_output(output_file_name, expected_output_file_name)

if __name__ == '__main__':

    if len(sys.argv) != 5:
        print('Usage: python checker.py <executable> <input_file> <output_file> <expected_output_file>')
        sys.exit(1)

    print(run(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]))
