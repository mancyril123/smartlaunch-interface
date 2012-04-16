﻿/*
Ruben Oanta
SL Interface

Defines a custom textfield used throughout
the interface.
*/

package com.slskin.ignitenetwork.components
{
	import flash.display.MovieClip;
	import fl.text.TLFTextField;
	import flash.events.FocusEvent;
	import flash.events.Event;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.display.InteractiveObject;
	import flash.events.KeyboardEvent;
	import flashx.textLayout.formats.TLFTypographicCase;
	import com.slskin.ignitenetwork.Language;

	public class SLTextField extends MovieClip
	{
		/* Events */
		public static const FIELD_ERROR:String = "FieldError";
		public static const FIELD_VALID:String = "FieldValid";
		public static const VALIDATION_CHANGE:String = "ValidationChange";
		
		/* Consts */
		private const ERRORFIELD_PADDING:uint = 10;
		private const MAX_CHARS:uint = 50;
		private const DEFAULT_REQUIRED_TEXT:String = "Required";
		
		private var _hint:String; //stores the field hint string
		private var _field:TLFTextField; //stores a reference to the underlying tlf.
		private var _hasError:Boolean; //indicates that there is an error on the field.
		private var _required:Boolean; //indicates if this field is required.
		private var requiredText:String; //Translated string for "Required"
		private var errorField:MovieClip; //holds a reference to the error field
		private var validator:Function; //stores the validator function.
		private var hintTween:Tween; //Tween used to fade in / out hint field.
		private var errorTween:Tween; //Tween used to fade in / out error field.
		
		public function SLTextField(hint:String = "Field", v:Function = null) 
		{
			this.hint = hint;
			this.validator = v;
			this.required = false;
			this.requiredText = Language.translate("Required", this.DEFAULT_REQUIRED_TEXT);
		
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		/* Setters */
		public function set hint(s:String):void 
		{ 
			this._hint = s;
			if(this.fieldHint != null)
				this.fieldHint.text = s;
		}
		
		/* Correct an issue with how the TLF tabs */
		public override function set tabIndex(index:int):void
		{
			super.tabIndex = index;
			if(field != null)
				InteractiveObject(this.field.getChildAt(1)).tabIndex = index;
		}
		public function set required(b:Boolean):void { this._required = b; }
		public function set field(f:TLFTextField):void { this._field = f; }
		public function set fieldValidator(f:Function):void { this.validator = f; }
		public function set displayAsPassword(bool:Boolean):void { this.field.displayAsPassword = bool; }
		public function set text(s:String):void { this.field.text = s; }
		
		public function set upperCase(toUpper:Boolean):void 
		{
			if(toUpper)
				this.field.textFlow.typographicCase = TLFTypographicCase.UPPERCASE;
			else
				this.field.textFlow.typographicCase = TLFTypographicCase.DEFAULT;
		}
		
		
		/* Getters */
		//In certain cases, the _field variable is not set. The tlf variable
		//is though and they both point to the same object.
		public function get field():TLFTextField 
		{ 
			if(this._field == null)
				return this.tlf;
			else
				return this._field; 
		}
		public function get hint():String { return this._hint; }
		public function get text():String { return this.field.text; }
		public function get hasError():Boolean { return this._hasError; }
		public function get required():Boolean { return this._required; }
		
		/*
		Event listener for added to stage event.
		*/
		private function onAdded(evt:Event):void
		{
			this.field = this.tlf; //reference the tlf in the TextField mc.
			this.errorField = this.ef; //reference the errorfield obj in the mc.
			
			//see if the field is enabled
			if(this.enabled)
				enable();
			else
				disable();
			
			//setup the tlf field
			if(this.field.maxChars == 0)
				this.field.maxChars = MAX_CHARS;
			
			//hide hint if text is set.
			if(this.text != "")
				this.fieldHint.alpha = 0;
			else
				this.text = "";
			
			this.fieldHint.text = this.hint;
			this.field.tabEnabled = false;
			this.fieldHint.tabEnabled = false;
			
			//hide the error field
			this.errorField.visible = false; 

			//removing tabing on other children objects
			this.bg.tabEnabled = false;
			this.border.tabEnabled = false;
			this.errorField.tabChildren = false;
			InteractiveObject(this.fieldHint.getChildAt(1)).tabEnabled = false;
			
			//listen for field events
			this.field.addEventListener(FocusEvent.FOCUS_IN, onFieldFocusIn);
			this.field.addEventListener(FocusEvent.FOCUS_OUT, onFieldFocusOut);
			
			//validate on change
			this.field.addEventListener(Event.CHANGE, validate);
		}
		
		/*
		OnFieldFocusIn
		Dim the field hint.
		*/
		private function onFieldFocusIn(evt:FocusEvent):void
		{
			if(this.isEmpty())
				this.hintTween = new Tween(this.fieldHint, "alpha", Regular.easeOut, this.fieldHint.alpha, .4, .2, true);
				
			//listen for field change events
			this.field.addEventListener(Event.CHANGE, onFieldChange); 
		}
		
		/* 
		OnFieldChange
		Listens for field change event and updates 
		the field state.
		*/
		private function onFieldChange(evt:Event)
		{
			if(!this.isEmpty())
				this.fieldHint.alpha = 0;
			else 
				this.fieldHint.alpha = 1;
			
			//check if we the field is required
			this.checkRequired();
		}
		
		/*
		Handles focus out event.
		*/
		private function onFieldFocusOut(evt:FocusEvent):void
		{
			var f:TLFTextField = evt.currentTarget as TLFTextField;
			
			//show hint
			if(f.text.length <= 0)
				this.hintTween = new Tween(this.fieldHint, "alpha", Regular.easeIn, this.fieldHint.alpha, 1, .5, true);
			
			//remove field change event handler
			this.field.removeEventListener(Event.CHANGE, onFieldChange);
			
			//check if we the field is required
			checkRequired();
		}
		
		/*
		checkRequired
		Checks to see if the field is required and updates the
		error field if it is required and empty.
		Translate("Required", L("Required"))
		*/
		public function checkRequired():void
		{
			//isEmpty && required show error
			if(this.required)
			{
				if(this.isEmpty())
					this.showError(this.requiredText);
				else if(this.errorField.tlf.text == this.requiredText)
					this.hideError();
			}
		}
		
		/*
		addKeyDownListener
		A wrapper to access the interactive object under the tlf and 
		add the key down listener.*/
		public function addKeyDownListener(callback:Function):void {
			InteractiveObject(this.field.getChildAt(1)).addEventListener(KeyboardEvent.KEY_DOWN, callback);
		}
		
		/* 
		validate 
		validates the field based on the validator. Also used as an event 
		handler for Event.CHANGE on the field.
		*/
		public function validate(evt:Event = null):void
		{
			if(this.validator == null) return;
			if(this.isEmpty()) return;
			
			var error:String = null;
			error = validator(this.text);
			
			if(error != null)
				this.showError(error);  
			else
				this.hideError();
		}
		
		/*
		showError
		Displays the error field.
		*/
		public function showError(error:String):void
		{
			//change the border to red!
			var c:ColorTransform = new ColorTransform();
			c.color = 0x990000;
			(this.border as Sprite).transform.colorTransform = c;
			
			//set error
			this.errorField.tlf.text = error;
			
			//set width of error field mc based on text length
			var textWidth:uint = this.errorField.tlf.textWidth + ERRORFIELD_PADDING;
			this.errorField.tlf.width = textWidth;
			this.errorField.bg.width = textWidth;
			
			//position the field correctly
			this.errorField.x = this._field.width +(ERRORFIELD_PADDING/2);
			
			//if the field is not visible
			if(!errorField.visible)
			{
				this.errorField.alpha = 0;
				this.errorField.visible = true;
				this.errorTween = new Tween(this.errorField, "alpha", Strong.easeIn, this.errorField.alpha, 1, .5, true);
			}
			
			//TO DO: Create a custom event and pass around hasError
			//as part of the event to avoid using this tmpHasError.
			var tmpHasError:Boolean = this.hasError;
				
			this._hasError = true;
			
			//check to see if we have changed validation
			if(tmpHasError != this.hasError)
				this.dispatchEvent(new Event(SLTextField.VALIDATION_CHANGE));
			
			//dispatch field error event
			this.dispatchEvent(new Event(SLTextField.FIELD_ERROR));
		}
		
		/*
		Hides the error field.
		*/
		public function hideError():void
		{
			//change the border to normal color
			var c:ColorTransform = new ColorTransform();
			c.color = 0x999999;
			(this.border as Sprite).transform.colorTransform = c;
			
			//hide error field
			this.errorField.tlf.text = "";
			this.errorField.x = this._field.width;
			this.errorField.tlf.width = 0;
			this.errorField.bg.width = 0;
			this.errorField.visible = false;
				
			//TO DO: Create a custom event and pass around hasError
			//as part of the event to avoid using this tmpHasError.
			var tmpHasError:Boolean = this.hasError;
			
			//reset error flag
			this._hasError = false;
			
			//check to see if we have changed validation
			if(tmpHasError != this.hasError)
				this.dispatchEvent(new Event(SLTextField.VALIDATION_CHANGE));
			
			//dispatch field valid event
			this.dispatchEvent(new Event(SLTextField.FIELD_VALID));
		}
		
		/* 
		disable
		Disable the field. Make the underlying tlf 
		unaccessible and the field appear disabled.
		*/
		public function disable():void
		{
			this.alpha = .2;
			this.enabled = false;
			if(field != null)
			{
				this._field.selectable = false;
				this._field.type = "dynamic";
				InteractiveObject(this._field.getChildAt(1)).tabEnabled = false;
			}
		}
		
		/*
		enable
		Enable the field. Reverse the affects of
		disable().
		*/
		public function enable():void
		{
			this.alpha = 1;
			this.enabled = true;
			
			if(field != null)
			{
				this.field.selectable = true;
				this.field.type = "input";
				InteractiveObject(this.field.getChildAt(1)).tabEnabled = true;
			}
		}
		
		/*
		clearField
		clears the text in the field and the error on the field.
		*/
		public function clearField():void
		{
			this.field.text = "";
			this.hideError();
			//show hint
			this.fieldHint.alpha = 1;
		}
		
		/* 
		isEmpty
		Returns true if the field has no text.
		*/
		public function isEmpty():Boolean
		{
			return (this.field.text.length == 0);
		}

	}//class
}//package