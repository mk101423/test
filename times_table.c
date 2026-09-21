#include <stdio.h>

int main(void) {
    int number;

    printf("Enter a number: ");
    scanf("%d", &number);

    for (int i = 1; i <= 5; i++) {
        printf("%d x %d = %d\n", number, i, number * i);
    }

    return 0;
}
