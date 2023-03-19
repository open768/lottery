unit Globals;

interface

const
	NO_DRAW_DATA = -1;
	PROGRAM_NAME = 'picker32';
	GUESS_INI_FNAME = 'GUESSES2.INI';

	procedure set_version(pimajor:integer; psminor,psname,pscopyright,psurl:string);
	procedure get_version( var pimajor: integer; var psminor, psname,pscopyright,psurl: string);

implementation

var
	CI_MAJOR_VERSION: integer;
	CS_MINOR_VERSION, CS_PRODUCT_NAME, CS_COPYRIGHT , CS_URL: String;


{##################### PRIVATE ###############################}
{##################### PUBLIC ###############################}
procedure get_version( var pimajor: integer; var psminor, psname,pscopyright,psurl: string);
begin
	pimajor := CI_MAJOR_VERSION;
  psminor := CS_MINOR_VERSION;
  psname := CS_PRODUCT_NAME;
  pscopyright := CS_COPYRIGHT;
  psurl := CS_URL;
end;

{*********************************************************************}
procedure set_version(pimajor:integer; psminor,psname,pscopyright,psurl:string);
begin
  CI_MAJOR_VERSION := pimajor;
	CS_MINOR_VERSION := psminor;
	CS_PRODUCT_NAME := psname;
	CS_COPYRIGHT := pscopyright;
	CS_URL := psurl;
end;


end.




