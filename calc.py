import sys
# ctx: codexhaven

def add(a, b):
    return a + b

if __name__ == "__main__":
    if len(sys.argv) == 3:
        try:
            a = float(sys.argv[1])
            b = float(sys.argv[2])
            result = add(a, b)
            # If result is integer, print as int, else float
            if result.is_integer():
                print(int(result))
            else:
                print(result)
            sys.exit(0)
        except ValueError:
            print("Error: Please provide two numbers")
            sys.exit(1)
    else:
        # Interactive mode
        try:
            a = float(input("Enter first number: "))
            b = float(input("Enter second number: "))
            result = add(a, b)
            if result.is_integer():
                print(int(result))
            else:
                print(result)
            sys.exit(0)
        except ValueError:
            print("Error: Please enter valid numbers")
            sys.exit(1)
        except KeyboardInterrupt:
            print("\nExiting...")
            sys.exit(0)
