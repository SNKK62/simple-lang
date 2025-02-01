# 実行結果

## フロントエンド

### 1

```sh
$ cat ./scripts/frontend-comment.spl
{
  int k = 0;
  k = 10;
  // This is a comment.
  iprint(k); // print 'k'
  sprint("\n");

  return 0;
}
$ ./simc ./scripts/frontend-comment.spl
$ ./a.out
10
```

### 2

```sh
$ cat ./scripts/frontend-syntax-error.spl
{
        int a, b, m, n r; // error occurs without comma

        sprint ("You must give 2 integers.\n");
        sprint ("First integer: ");
        scan  (a);
        sprint ("Second integer: ");
        scan (b);
        m = a; n = b;
        r = m - (m / n) * n;
        m = n;
        n = r;
        a < b; // error occurs with invalid operator
        while (r > 0;) { // error occurs with excessive semicolon
                r = m - (m / n) * n;
                m = n;
                n = r;
                {} // error occurs with empty block
        }
        if (n = m) { // error occurs with invalid comparison
                sprint("error");
        }
        sprint ("Answer = ");
        iprint (m) // error occurs without semicolon at end of line
        sprint ("\n");
}
$ ./simc ./scripts/frontend-syntax-error.spl
Syntax error at line 2, column 16-17
 int a, b, m, n r; // error occurs without comma
                ^^
Syntax error at line 13, column 3-4
 a < b; // error occurs with invalid operator
   ^^
Syntax error at line 14, column 13-14
 while (r > 0;) { // error occurs with excessive semicolon
             ^^
Syntax error at line 18, column 3-4
  {} // error occurs with empty block
   ^^
Syntax error at line 20, column 7-8
 if (n = m) { // error occurs with invalid comparison
       ^^
Syntax error at line 25, column 1-7
 sprint ("\n");
 ^^^^^^^
```

## バックエンド

### 1 `%`
```sh
$ cat ./scripts/backend-mod.spl
{
    int i, c;
    int[10] a, b;
    new(a);
    new(b);

    a[0] = 10;
    a[1] = 32;
    a[2] = 56;
    a[3] = 62;
    a[4] = 92;
    a[5] = 79;
    a[6] = 27;
    a[7] = 61;
    a[8] = 39;
    a[9] = 53;

    b[0] = 8;
    b[1] = 11;
    b[2] = 9;
    b[3] = 7;
    b[4] = 4;
    b[5] = 20;
    b[6] = 7;
    b[7] = 2;
    b[8] = 1;
    b[9] = 8;

    while (i < 10) {
        c = a[i] % b[i];
        iprint(a[i]);
        sprint(" %% ");
        iprint(b[i]);
        sprint(" = ");
        iprint(c);
        sprint("\n");
        i = i + 1;
    }

    return 0;
}
$ ./simc ./scripts/backend-mod.spl
$ ./a.out
10 % 8 = 2
32 % 11 = 10
56 % 9 = 2
62 % 7 = 6
92 % 4 = 0
79 % 20 = 19
27 % 7 = 6
61 % 2 = 1
39 % 1 = 0
53 % 8 = 5
```

### 2 代入宣言
```sh
$ cat ./scripts/backend-assign-dec.spl
{
    int a = 20;
    type ID = int;
    ID b = 30;

    sprint("int a = ");
    iprint(a);
    sprint("\n");

    sprint("ID b = ");
    iprint(b);
    sprint("\n");

    return 0;
}
$ ./simc ./scripts/backend-assign-dec.spl
$ ./a.out
int a = 20
ID b = 30
```

### 3 `^`
```sh
$ cat ./scripts/backend-power.spl
{
    int a = 5^3;
    int b = 6;
    int c = 2;

    sprint("a = ");
    iprint(a);
    sprint("\n");

    sprint("b = ");
    iprint(b);
    sprint("\n");

    sprint("c = ");
    iprint(c);
    sprint("\n");

    sprint("b ^ (c + 1) = ");
    iprint(b ^ (c + 1));
    sprint("\n");

    return 0;
}
$ ./simc ./scripts/backend-power.spl
$ ./a.out
a = 125
b = 6
c = 2
b ^ (c + 1) = 216
```

### 4 `++`
```sh
$ cat ./scripts/backend-pp.spl
{
    int a, b;

    a = 20;
    b = a++;

    sprint("a = ");
    iprint(a);
    sprint("\n");

    sprint("b = ");
    iprint(b);
    sprint("\n");

    return 0;
}
$ ./simc ./scripts/backend-pp.spl
$ ./a.out
a = 21
b = 20
```

### 5 `+=`
```sh
$ cat ./scripts/backend-p-eq.spl
{
    int a = 20;

    a += 2;

    sprint("a = ");
    iprint(a);
    sprint("\n");

    return 0;
}
$ ./simc ./scripts/backend-p-eq.spl
$ ./a.out
a = 22
```

### 6 `do while`
```sh
$ cat ./scripts/backend-do-while.spl
{
    int a = 7;

    do {
        sprint("a = ");
        iprint(a);
        sprint("\n");
        a += 1;
    } while (a < 11);

    do {
        sprint("a = ");
        iprint(a);
        sprint("\n");
        a += 1;
    } while (a < 11);

    return 0;
}
$ ./simc ./scripts/backend-do-while.spl
$ ./a.out
a = 7
a = 8
a = 9
a = 10
a = 11
```

### 7 `for`
```sh
$ cat ./scripts/backend-for.spl
{
    for (i = 10..15) {
        sprint("i = ");
        iprint(i);
        sprint("\n");
    }

    return 0;
}
$ ./simc ./scripts/backend-for.spl
$ ./a.out
i = 10
i = 11
i = 12
i = 13
i = 14
```

## 独自機能

### `break`と`continue`の実装
```sh
$ cat ./scripts/backend-original.spl
{
    int a = 10;
    while (a < 15) {
        if (a == 13)
            break;
        sprint("a = ");
        iprint(a);
        sprint("\n");
        a += 1;

        continue;

        sprint("Hello World");
        sprint("\n");
    }

    for (i =  10..15) {
        if (i == 13)
            break;
        sprint("i = ");
        iprint(i);
        sprint("\n");

        continue;

        sprint("Hello World");
        sprint("\n");
    }

    return 0;
}
$ ./simc ./scripts/backend-original.spl
$ ./a.out
a = 10
a = 11
a = 12
i = 10
i = 11
i = 12
```

## 元からあるファイルの実行結果
- `sort.spl`
```sh
$ cat ./scripts/sort.spl
{
       int[10] a;
       int size;

       void init() {
          int i;

          i = 0;
          while (i < size) {
              a[i] = size - i;
              i = i+1;
          }
       }

       void print() {
          int i;

          i = 0;
          while (i < size) {
              iprint(a[i]);
              sprint(" ");
              i = i+1;
          }
          sprint("\n");
       }

       void sort(int i) {
          void min (int j) {
              void swap(int i, int j) {
                  int tmp;

                  tmp = a[i];
                  a[i] = a[j];
                  a[j] = tmp;
              }


              if (j < size) {
                   if (a[j] < a[i]) swap(i,j);
                   min (j+1);
             }
          }

          if (i < size) {
                  min(i+1);
                  sort(i+1);
          }
     }

     size = 10;
     new(a);
     init();
     sprint("before sorting\n");
     print();
     sort(0);
     sprint("after sorting\n");
     print();
}

$ ./simc ./scripts/sort.spl
$ ./a.out
before sorting
10 9 8 7 6 5 4 3 2 1
after sorting
1 2 3 4 5 6 7 8 9 10
```

- sample.spl
```sh
$ cat ./scripts/sample.spl
{
        int a, b, m, n, r;

        sprint ("You must give 2 integers.\n");
        sprint ("First integer: ");
        scan  (a);
        sprint ("Second integer: ");
        scan (b);
        m = a; n = b;
        r = m - (m / n) * n;
        m = n;
        n = r;
        while (r > 0) {
                // r = m - (m / n) * n;
                r = m % n;

                m = n;
                n = r;
        }
        sprint ("Answer = ");
        iprint (m) ;
        sprint ("\n");
}
$ ./simc ./scripts/sample.spl
$ ./a.out
You must give 2 integers.
First integer: 30
Second integer: 66
Answer = 6
```

