import time
#     hdr = '+-' + (map(lambda x: '-'*x, widths)).join('-+-') + '-+'

def quick(*argv):
    GREEN = "\033[0;32m"
    END = "\033[0m"
    print(f"{GREEN}[" + f"][".join(str(x) for x in argv) + f"]{END}")


def message(*argv):
    now = time.localtime()
    print("\n====> " + time.asctime(now))
    for arg in argv:
        print(arg)

def dump_table(hdr: list, table: list):

    widths = list( map(len, hdr))
    for row in table:
        for i in range(len(row)):
            if i == len(widths):
                widths.append(0)

            if widths[i] < len(row[i]):
                widths[i] = len(row[i])


    border = '+-' + '-+-'.join(map(lambda x: '-'*x, widths)) + '-+'
    print(border)
    print('| ' + ' | '.join(map(lambda x: hdr[x].ljust(widths[x]), range(len(hdr)))) + ' |')

    print(border)
    for row in table:
        print('| ' + ' | '.join(map(lambda x: row[x].ljust(widths[x]), range(len(row)))) + ' |')

    print(border)

