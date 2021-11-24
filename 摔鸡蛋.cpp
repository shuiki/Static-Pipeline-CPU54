#include<stdio.h>
#include<limits.h>

typedef struct {
	int times;
	int div;
}Unit;


int main()
{
	int i, j, k, t, max, cdiv, a, b;

	const int eggs = 5, floors = 25, limit = 4;

	Unit temp[eggs + 1][floors + 1];

	for (i = 0; i < floors + 1; ++i)
	{
		temp[0][i] = {0,0};
		temp[1][i] = {i,1};
	}

	for (i = 2; i < eggs + 1; ++i)
	{
		temp[i][0] = {0,0};
		temp[i][1] = {1,1};
	}

	for (i = 2; i < eggs + 1; ++i)
	{
		for (j = 2; j < floors + 1; ++j)
		{
			for (k = 1, max = INT_MAX, cdiv = 0; k < j; ++k)
			{
				if (temp[i][k - 1].times > temp[i - 1][j - k].times)
				{
					t = temp[i][k - 1].times;
				}
				else
				{ 
					t = temp[i - 1][j - k].times;
				}

				if (max >= t)
				{
					max = t;
					cdiv = j - k + 1;
				}
			}
			temp[i][j].times = max + 1;
			temp[i][j].div = cdiv;
		}
	}
	int eggUsed=0, timesTried=INT_MAX;
	for (int t = 0; t <= eggs; t++)
	{
		if (temp[t][floors].times < timesTried&& temp[t][floors].times>0)
		{
			eggUsed = t;
			timesTried = temp[t][floors].times;
		}
	}
	printf("Own %d eggs, highest floor is %d floor\n",eggs, floors);
	printf("Expect: Try %d times with %d eggs.\n", timesTried, eggUsed);
	int actualTryTime = 0, brokenEggs = 0, curFloor = 0, lastFloor = 0, maxFloor = floors, minFloor = 1;//全局的值
	int curLimit = limit, curDiv = 0;//局部的值
	bool hit = false, near = false, curBreak = false;
	a = eggUsed; b = floors;
	printf("Attempts: ");
	for (int i = 0; i < timesTried; i++)
	{
		lastFloor = curFloor;
		curDiv = temp[a][b].div;
		curFloor = curDiv + minFloor - 1;
		printf("%d ", curFloor);
		actualTryTime++;
		if (curFloor == limit)
			hit = true;
		else if ((curFloor - limit) == 1)
			near = true;
		if (curDiv > curLimit)//break
		{
			a = a - 1;
			b = curFloor - minFloor;
			maxFloor = curFloor - 1;
			brokenEggs++;
			curBreak = true;
		}
		else//not break
		{
			b = maxFloor - curFloor;
			minFloor = curFloor + 1;
			curLimit -= curDiv;
			curBreak = false;
		}
		if (hit&&near)
			break;
	}
	int usedEggs = curBreak ? brokenEggs : brokenEggs + 1;
	printf("\nLimit: %d",limit);
	printf("\nActuallyTried: %d\nusedEggs: %d\n",actualTryTime,usedEggs);
	if (curBreak)
	{
		printf("last one broken.");
	}
	else
	{
		printf("last one not broken.");
	}
	getchar();
	return 0;
}