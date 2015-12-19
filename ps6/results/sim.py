from scipy import stats

def main():
    f27_scan = open('sim_scan27.txt', 'r')
    f27_table = open('sim_table27.txt', 'r')
    f35932_scan = open('sim_scan35932.txt', 'r')
    f35932_table = open('sim_table35932.txt', 'r')
    
    ntests = 10
    
    scan27 = [0 for i in range(ntests)]
    table27 = [0 for i in range(ntests)]
    scan35932 = [0 for i in range(ntests)]
    table35932 = [0 for i in range(ntests)]

    files = [f27_scan, f27_table, f35932_scan, f35932_table]
    arrs = [scan27, table27, scan35932, table35932]

    for i in range(ntests):
        for j in range(4):
            line = files[j].readline()
            if line[len(line)-1] == '\n':
                line = line[:len(line)-1]
            arrs[j][i] = float(line)
    for j in range(4):
        files[j].close()

    _, p27 = stats.ttest_ind(scan27, table27, equal_var=False)
    mean27scan = stats.tmean(scan27)
    mean27table = stats.tmean(table27)
    var27scan = stats.tvar(scan27)
    var27table = stats.tvar(table27)

    _, p35932 = stats.ttest_ind(scan35932, table35932, equal_var=False)
    mean35932scan = stats.tmean(scan35932)
    mean35932table = stats.tmean(table35932)
    var35932scan = stats.tvar(scan35932)
    var35932table = stats.tvar(table35932)

    f = open('sim_results_compare_scan_table.txt', 'w')
    f.write('27\n')
    f.write('scan mean: ' + str(mean27scan) + '\n')
    f.write('scan var: ' + str(var27scan) + '\n')
    f.write('table mean: ' + str(mean27table) + '\n')
    f.write('table var: ' + str(var27table) + '\n')
    f.write('p-value: ' + str(p27) + '\n\n')

    f.write('35932\n')
    f.write('scan mean: ' + str(mean35932scan) + '\n')
    f.write('scan var: ' + str(var35932scan) + '\n')
    f.write('table mean: ' + str(mean35932table) + '\n')
    f.write('table var: ' + str(var35932table) + '\n')
    f.write('p-value: ' + str(p35932) + '\n')

    f.close()

if __name__ == '__main__':
    main()
