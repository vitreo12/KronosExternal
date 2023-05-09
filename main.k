Import Algorithm
Import IO
Import Math
Import Vector

;;;;;;;;;;;;;;;;;
; Sampling rate ;
;;;;;;;;;;;;;;;;;

SampleRate() {
  Rate-of(Audio:Signal(0))
}

Sample-Rate() {
  SampleRate()
}

;;;;;;;;;;;;;;;;;;;
; Math extensions ;
;;;;;;;;;;;;;;;;;;;

Package Math {
  NextPow2(x:Real!) {
    Math:Pow(#2 Ceil(Math:Log(x) / Math:Log(#2)))
  }
}

;;;;;;;;;;
; String ;
;;;;;;;;;;

Package String {
  String?(t) {
    Equal-Type(Class-Of(t) Class-Of(""))
  }

  Replace(text:String! find:String! replace:String!) {
    pos = String:Find(text find)
    remainder = String:Skip(text pos + String:Length(find))
    When(pos >= #0
      String:Concat(String:Take(text pos) replace Recur(remainder find replace))
    Otherwise
      text
    )
  }

  Convert-Invariant(val:Constant!) {
    Replace(String:Convert(val) "." "d")
  }
}

Constraints:String!(t) #[Pattern] {
  When(String:String?(t) t)
}

;;;;;;;;;
; Param ;
;;;;;;;;;

Package Param {
  Priority = #1
  Clock = Reactive:Tick(Priority "Params")

  Signal(sig) {
    Reactive:Resample(sig Clock)
  }

  New(key:String!) {
    keyWithDefault = String:Concat(String:Concat(key "_default") #0)
    Signal(External(keyWithDefault Coerce(Float #0)))
  }

  New(key:String! default:Constant!) #[Extend] {
    defaultConvert = String:Convert-Invariant(default)
    keyWithDefault = String:Concat(String:Concat(key "_default") defaultConvert)
    Signal(External(keyWithDefault Coerce(Float default)))
  }

  New(key:String! default:Constant! min:Real! max:Real!) #[Extend] {
    defaultConvert = String:Convert-Invariant(default)
    keyWithDefault = String:Concat(String:Concat(key "_default") defaultConvert)
    Math:Clamp(
      Signal(External(keyWithDefault Coerce(Float default)))
      min
      max
    )
  }
}

;;;;;;;;;;;;;;;;
; Buffer types ;
;;;;;;;;;;;;;;;;

Type Buffer(Data Params)
Type BufferParams(Size Frames NumChans SampleRate)

;;;;;;;;;;;;;;;;
; BufferParams ;
;;;;;;;;;;;;;;;;

Package BufferParams {
  Priority = #1
  Clock = Reactive:Tick(Priority "BufferParams")

  Signal(sig) {
    Reactive:Resample(sig Clock)
  }
  
  New(key:String!) {
    keyWithExt = String:Concat(key "_buffer_params") 
    Signal(External(keyWithExt Make(:BufferParams 0 0 0 44100)))
  }
}

;;;;;;;;;;
; Buffer ;
;;;;;;;;;;

Package Buffer {
  Cons(key:String! maxSize:Constant!) {
    data = External-Unsafe(
      String:Concat(key "_buffer_data") 
      Algorithm:Repeat(Math:NextPow2(maxSize) 0)
    )
    params = BufferParams:New(key)
    Make(:Buffer data params)
  }

  New(key:String!) {
    Cons(key #48000 * #30) ; Default 30s @ 48khz
  }

  New(key:String! maxSize:Constant!) #[Extend] {
    Cons(key maxSize)
  }

  Size(buf:Buffer!) {
    BufferParams:Size(Buffer:Params(buf))
  }

  Frames(buf:Buffer!) {
    BufferParams:Frames(Buffer:Params(buf))
  }

  NumChans(buf:Buffer!) {
    BufferParams:NumChans(Buffer:Params(buf))
  }

  SampleRate(buf:Buffer!) {
    BufferParams:SampleRate(Buffer:Params(buf))
  }

  Read(buf:Buffer! index:Real!) {
    data = Buffer:Data(buf)
    size = Buffer:Size(buf)
    Audio:Signal(Select-Wrap(data Math:Clamp(Coerce(Int32 index) #0 size - #1)))
  }

  Read(buf:Buffer! index:Real! channel:Real!) #[Extend] {
    data = Buffer:Data(buf)
    (size frames numChans _) = Break(:BufferParams Buffer:Params(buf))
    mcIndex = (Math:Clamp(Coerce(Int32 index) #0 frames - #1) * numChans) + channel
    Audio:Signal(Select-Wrap(data Math:Clamp(mcIndex #0 size - #1)))
  }

  ReadLinear(buf:Buffer! index:Real!) {
    data = Buffer:Data(buf)
    size = Buffer:Size(buf)
    index32 = Coerce(Int32 index)
    indices = Algorithm:Map(
      i => Audio:Signal(Select-Wrap(data Math:Clamp(index32 + i #0 size - #1)))
      (#0 #1)
    )
    Math:Linear-Interpolation(Fraction(index) indices)
  }

  ReadLinear(buf:Buffer! index:Real! channel:Real!) #[Extend] {
    data = Buffer:Data(buf)
    (size frames numChans _) = Break(:BufferParams Buffer:Params(buf))
    mcRead  = i => (i * numChans) + channel
    index32 = Math:Clamp(Coerce(Int32 index) #0 frames - #1)
    indices = Algorithm:Map(
      i => Audio:Signal(Select-Wrap(data Math:Clamp(mcRead(index32 + i) #0 size - #1)))
      (#0 #1)
    )
    Math:Linear-Interpolation(Fraction(index) indices)
  }

  ReadHermite(buf:Buffer! index:Real!) {
    data = Buffer:Data(buf)
    size = Buffer:Size(buf)
    index32 = Coerce(Int32 index)
    indices = Algorithm:Map(
      i => Audio:Signal(Select-Wrap(data Math:Clamp(index32 + i #0 size - #1)))
      (#-1 #0 #1 #2)
    )
    Math:Hermite-Interpolation(Fraction(index) indices)
  }

  ReadHermite(buf:Buffer! index:Real! channel:Real!) #[Extend] {
    data = Buffer:Data(buf)
    (size frames numChans _) = Break(:BufferParams Buffer:Params(buf))
    mcRead  = i => (i * numChans) + channel
    index32 = Math:Clamp(Coerce(Int32 index) #0 frames - #1)
    indices = Algorithm:Map(
      i => Audio:Signal(Select-Wrap(data Math:Clamp(mcRead(index32 + i) #0 size - #1)))
      (#-1 #0 #1 #2)
    )
    Math:Hermite-Interpolation(Fraction(index) indices)
  }
}
