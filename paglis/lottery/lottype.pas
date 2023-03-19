unit Lottype;

interface
uses sysutils,wintypes,graphics;
const
  MAX_LOTTERY_NUM =200;
  MAX_UK_LOTTERY_NUM =49;
  MAX_DRAWN_BALLS = 7;
  UK_BOARDS =7;
  UK_NSELECT = 6;
  IDPREFIX = 3;
  IDSTARTDATE = 4;
  DRAW_BEFORE_WINSDAY = 116;
  INVALID_LOTTERY_NUMBER = -1;
//  FLASHBALL_NAME = 'FLASHBALL';
 // YELLOWBALL_NAME = 'YELLOWBALL';
  //BLUEBALL_NAME = 'BLUEBALL';
 // GREENBALL_NAME = 'GREENBALL';
 // REDBALL_NAME = 'REDBALL';
 // WHITEBALL_NAME = 'WHITEBALL';
 //	PURPLEBALL_NAME = 'PURPLEBALL';
 //	BLACKBALL_NAME = 'BLACKBALL';
type
  ElotteryError =class(Exception);
  LottoBall = integer;

  TLottBallType = (Ball_Flash, Ball_White, Ball_red, Ball_Blue, Ball_Green, Ball_Yellow, Ball_Purple, Ball_Black);
  //TLottBallType = (ball_normal, Ball_Flash, Ball_Black);
  TDrawNumType = (Ball_1, Ball_2, Ball_3, Ball_4, Ball_5, Ball_6, Ball_Bonus);
	TLotteryDropStyle =
	(
		ldsNormal, ldsRandom, ldsHighestFirst,
		ldsColumns,ldsColumnsSnake
	);

implementation
end.

