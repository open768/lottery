unit stack;

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
type

TStackItem = class
	item: Tobject;
	next: TstackItem ;
end;

TStack =class
private
   m_root:TstackItem;
   function p_get_top_item: Tobject;
public
	constructor create;
   destructor destroy; override;
     
	procedure clear; overload;
	procedure clear(item:TstackItem); overload;
   function pop: Tobject;
   procedure push(obj:TObject);
   property top: TObject read p_get_top_item;
end;

implementation
	constructor TStack.create;
   begin
   	m_root := nil;
   end;
   
   destructor TStack.destroy; 
   begin
   	clear;
   end;
   
	//********************************************************
	procedure TStack.clear;
   begin
   	clear(m_root);
   end;

	//********************************************************
	procedure TStack.clear(item:TstackItem);
   begin
   	if item <> nil then
      begin
      	clear(item.next);
         item.next := nil;
         item.free;
      end;
   end;
   
	//********************************************************
   // it is the responsibility of the caller to free the popped items
   //*********************************************************
   function TStack.pop: Tobject;
   var
   	old_root: TstackItem;
   begin
   	if m_root = nil then
      	result := nil
      else
      	begin
		   	old_root := m_root;
            m_root := old_root.next;
         	result := old_root.item;
            
            old_root.free;
         end;
   end;

	//********************************************************
   procedure TStack.push(obj:TObject);
   var
   	new_root : TstackItem;
   begin
   	new_root := TstackItem.create();
      new_root.item := obj;
      new_root.next := m_root;
      m_root := new_root;
   end;

	//********************************************************
   function TStack.p_get_top_item: TObject;
   begin
   	if m_root = nil then
      	result:= nil
      else
      	result := m_root.item; 
   end;

end.
 
