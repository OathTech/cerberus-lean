int pick(int x)
{
  int t = 3;
  if (x > t) {
    return x - t;
  } else {
    return x + t;
  }
}

int main(void)
{
  return pick(10);
}
