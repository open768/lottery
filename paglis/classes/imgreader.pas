unit imgreader;
//
//****************************************************************
//* Copyright 2004 Paglis Software
//*
//* This source code is the intellectual property of 
//* Paglis Software and protected by Intellectual and 
//* international copyright Law.
//*
//* A free license is provided to use this code for any non commercial purpose
//* on the understanding that this copyright message must be retained
//* on all derivatives of the code and any risk or consequences of using this
//* code is the responsibility solely of the person using this code
//*
//* Contact  http://www.paglis.co.uk/
//*
//****************************************************************
//*

interface
	uses
		classes, jpeg;

	//***********************************************************************
	type
		TImageReaderThread = class (TThread)
		private
			C_image_name: string;
		public
			Jpg: TJPEGImage;
			procedure execute; override;
			constructor Create(image_name: string);
			destructor destroy; override;
	end;

implementation
	//**********************************************************
	destructor TImageReaderThread.destroy;
	begin
		if assigned(jpg) then jpg.free;
		inherited destroy;
	end;

	//**********************************************************
	constructor TImageReaderThread.Create(image_name:string);
	begin
		inherited create(false);
		freeonterminate := true;
		C_image_name:= image_name;
		Jpg := nil;
	end;
	
	//**********************************************************
	procedure TImageReaderThread.execute;
	begin
		Jpg:= TJPEGImage.create();
		jpg.LoadFromfile(C_image_name);			//could well fall over here
	end;
end.
