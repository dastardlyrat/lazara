#ifndef OCCULT_API_SAFEMATH_FXH
#define OCCULT_API_SAFEMATH_FXH

uint OCCULT_UIntModuloNoWarn(uint value, uint divisor)
{
    return (divisor == 0u) ? 0u : (value - ((value / divisor) * divisor));
}

int OCCULT_IntModuloNoWarn(int value, int divisor)
{
    uint d = (uint)max(abs(divisor), 1);
    uint v = (uint)abs(value);
    uint r = OCCULT_UIntModuloNoWarn(v, d);
    return (value < 0) ? -(int)r : (int)r;
}

uint OCCULT_UIntDivNoWarn(uint value, uint divisor)
{
    return (divisor == 0u) ? 0u : (value / divisor);
}

float OCCULT_SafePow(float baseValue, float exponentValue)
{
    return pow(max(baseValue, 0.0), exponentValue);
}

float OCCULT_SafeRcp(float value, float fallbackValue)
{
    return (abs(value) > 1.0e-6) ? (1.0 / value) : fallbackValue;
}

#endif // OCCULT_API_SAFEMATH_FXH
