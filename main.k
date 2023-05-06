Import Algorithm
Import IO
Import Math
Import Vector

SampleRate() {
	Rate-of(Audio:Signal(0))
}

Sample-Rate() {
	SampleRate()
}

Package Math {
	NextPow2(x:Real!) {
		Math:Pow(#2 Ceil(Math:Log(x) / Math:Log(#2)))
	}
}

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

Package Block {
	Priority = #1
	Clock = Reactive:Tick(Priority "block")

	Signal(sig) {
		Reactive:Resample(sig Clock)
	}

	Param(key:String!) {
		keyWithDefault = String:Concat(String:Concat(key "_default") #0)
		Signal(External(keyWithDefault Coerce(Float #0)))
	}

	Param(key:String! default:Constant!) #[Extend] {
		defaultConvert = String:Convert-Invariant(default)
		keyWithDefault = String:Concat(String:Concat(key "_default") defaultConvert)
		Signal(External(keyWithDefault Coerce(Float default)))
	}

	Param(key:String! default:Constant! min:Real! max:Real!) #[Extend] {
		defaultConvert = String:Convert-Invariant(default)
		keyWithDefault = String:Concat(String:Concat(key "_default") defaultConvert)
		Math:Clamp(
			Signal(External(keyWithDefault Coerce(Float default)))
			min
			max
		)
	}
}

Package Param {
	New(key:String!) {
        Block:Param(key)
	}

	New(key:String! default:Constant!) #[Extend] {
        Block:Param(key default)
	}

	New(key:String! default:Constant! min:Real! max:Real!) #[Extend] {
        Block:Param(key default min max)
	}
}

Type Buffer(Data Size Frames NumChans SampleRate)

Package Buffer {
	Cons(key:String! maxSize:Constant!) {
		data = External-Unsafe(String:Concat(key "_buffer") Algorithm:Repeat(Math:NextPow2(maxSize) 0))
		size = Block:Param(String:Concat(key "_size") #1)
		frames = Block:Param(String:Concat(key "_frames") #1)
		numChans = Block:Param(String:Concat(key "_num_chans") #1)
		sampleRate = Block:Param(String:Concat(key "_sample_rate") #44100)
		Make(:Buffer data size frames numChans sampleRate)
	}

  New(key:String!) {
      Cons(key #48000 * #30)
  }

	New(key:String! maxSize:Constant!) #[Extend] {
		Cons(key maxSize)
	}

	Read(buf:Buffer! index:Real!) {
		(data size _ _ _) = Break(:Buffer buf)
		Audio:Signal(Select-Wrap(data Math:Clamp(Coerce(Int32 index) #0 size - #1)))
	}

	Read(buf:Buffer! index:Real! channel:Real!) #[Extend] {
		(data size frames numChans _) = Break(:Buffer buf)
		mcIndex = (Math:Clamp(Coerce(Int32 index) #0 frames - #1) * numChans) + channel
		Audio:Signal(Select-Wrap(data Math:Clamp(mcIndex #0 size - #1)))
	}

	ReadLinear(buf:Buffer! index:Real!) {
		(data size _ _ _) = Break(:Buffer buf)
		index32 = Coerce(Int32 index)
		indices = Algorithm:Map(
			i => Audio:Signal(Select-Wrap(data Math:Clamp(index32 + i #0 size - #1)))
			(#0 #1)
		)
		Math:Linear-Interpolation(Fraction(index) indices)
	}

	ReadLinear(buf:Buffer! index:Real! channel:Real!) #[Extend] {
		(data size frames numChans _) = Break(:Buffer buf)
		mcRead  = i => (i * numChans) + channel
		index32 = Math:Clamp(Coerce(Int32 index) #0 frames - #1)
		indices = Algorithm:Map(
			i => Audio:Signal(Select-Wrap(data Math:Clamp(mcRead(index32 + i) #0 size - #1)))
			(#0 #1)
		)
		Math:Linear-Interpolation(Fraction(index) indices)
	}

	ReadHermite(buf:Buffer! index:Real!) {
		(data size _ _ _) = Break(:Buffer buf)
		index32 = Coerce(Int32 index)
		indices = Algorithm:Map(
			i => Audio:Signal(Select-Wrap(data Math:Clamp(index32 + i #0 size - #1)))
			(#-1 #0 #1 #2)
		)
		Math:Hermite-Interpolation(Fraction(index) indices)
	}

	ReadHermite(buf:Buffer! index:Real! channel:Real!) #[Extend] {
		(data size frames numChans _) = Break(:Buffer buf)
		mcRead  = i => (i * numChans) + channel
		index32 = Math:Clamp(Coerce(Int32 index) #0 frames - #1)
		indices = Algorithm:Map(
			i => Audio:Signal(Select-Wrap(data Math:Clamp(mcRead(index32 + i) #0 size - #1)))
			(#-1 #0 #1 #2)
		)
		Math:Hermite-Interpolation(Fraction(index) indices)
	}
}
