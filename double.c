#include <stdio.h>

double doubleValue(double value) {
    return value * 2;
}

int main(void) {
    double number;

    printf("Enter a number: ");
    scanf("%lf", &number);

    printf("Doubled: %g\n", doubleValue(number));

    return 0;
}
