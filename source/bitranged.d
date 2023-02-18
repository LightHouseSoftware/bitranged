module bitranged;

struct BitRange
{
	private {
		// storage of bits
		ubyte[] _bits;
		// real capacity
		ulong   _capacity;
		// counter of bits
		ulong   _counter;
		
		// get nth bit of byte
		ubyte bitOf(ubyte value, ubyte n)
		{
			return (value >> n) & 1;
		}
		
		// nearest power of two
		ulong cpl2(ulong x)
		{
			if (x == 0)
			{
				return 0;
			}
		
			x -= 1UL;
			
			x = x | (x >> 1UL);
			x = x | (x >> 2UL);
			x = x | (x >> 4UL);
			x = x | (x >> 8UL);
			x = x | (x >> 16UL);
			x = x | (x >> 32UL);
		
			return (x == ulong.max) ? ulong.max : (x + 1UL);
		}
		
		// get indexes of byte and bit in bit array
		auto indices(ulong index)
		{
			auto numberOfByte = index >> 3;
			auto numberOfBit = 0x07u - cast(ubyte) (index - (numberOfByte << 3));
			
			return [numberOfByte, numberOfBit];
		}
		
		// set bit to 1
		ubyte setBit(ubyte value, ubyte n)
		{
			return cast(ubyte) (value | (1 << n));
		}
		
		// deconstruct value to little-endian byte array
		ubyte[] toLEBytes(T)(T value)
		{
			if (T.sizeof <= 1)
			{
				return [cast(ubyte) value];
			}
			else
			{
				ubyte[] bytes;
				
				T MASK    = cast(T) 0xff;
				T NSHIFTS = (T.sizeof - 1) << 3;
				
				foreach (i; 0..T.sizeof)
				{
					bytes ~= cast(ubyte) ((value & (MASK << NSHIFTS)) >> NSHIFTS);
					NSHIFTS -= 8;
				}
				
				return bytes;
			}
		}
		
		// set bit to 0
		ubyte unsetBit(ubyte value, ubyte n)
		{
			return cast(ubyte) (value & ~(1u << n));
		}
	}

	this(ulong n)
	{
		_capacity     = n;
		_counter      = 0;

		if ((0 < n) & (n < 8))
		{
			_bits ~= 0x00;	
		}
		else
		{
			foreach (i; 0..(cpl2(n) >> 3))
			{
				_bits ~= 0x00;
			}
		}
	}
	
	ubyte[] asBytes()
	{
		return _bits;
	}

	bool empty() 
	{
		return (_counter == _capacity);
	}
	
	void fromString(string s)
	{
		auto length = s.length;
		auto size   = (length < 8) ? 1 : cpl2(length) >> 3;
		
		_bits = [];
		
		foreach (_; 0..size)
		{
			_bits ~= 0x00u;
		}
		
		foreach (e; s)
		{
			if (e == 0x30)
			{
				this.opIndexAssign(0, _counter);
			}
			else
			{
				if (e == 0x31)
				{
					this.opIndexAssign(1, _counter);
				}
				else
				{
					continue;
				}
			}
			_counter++;
		}
		
		_capacity = _counter;
		_counter  = 0;
	}

	ubyte front()
	{
		auto indexes = indices(_counter);
		
		return bitOf(_bits[indexes[0]], cast(ubyte) indexes[1]);
	}
	
	void grow(ulong size)
	{
		if (size > 0)
		{
			if (_capacity >= size)
			{
				throw new Exception("Invalid size for growing BitRange. New size conflicts with real capacity of bit array.");
			}
			else
			{
				auto realSize = (size < 8) ? 1 : cpl2(size) >> 3;
				auto newSize = realSize - _bits.length;
				
				foreach (_; 0..newSize)
				{
					_bits ~= 0x00u;
				}
				
				_capacity = size;
			}
		}
	}
	
	ulong length()
	{
		return _capacity;
	}
	
	ubyte opIndex(size_t index)
	{
		auto indexes = indices(index);
		
		return bitOf(_bits[indexes[0]], cast(ubyte) indexes[1]);	
	}
	
	void opIndexAssign(ubyte value, size_t index)
	{
		auto indexes = indices(index);
		auto currentByte = _bits[indexes[0]];
		
		if (value)
		{
			currentByte =  setBit(currentByte, cast(ubyte) indexes[1]);
		}
		else
		{
			currentByte = unsetBit(currentByte, cast(ubyte) indexes[1]);
		}
	
		_bits[indexes[0]] = currentByte;
	}

	void popFront()
	{
		_counter++;
	}

	void push(T)(T value)
	{
		auto bytes = toLEBytes(value);
		
		_capacity += bytes.length * 8;
		_bits ~= bytes;
	}
	
	void push(T)(T[] values)
	{
		foreach (e; values)
		{
			push(e);
		}
	}
	
	void shrink(ulong size)
	{
		if (size == 0)
		{
			_bits = [];
			_capacity = 0;
		}
		else
		{
			if (size >= _capacity)
			{
				throw new Exception("Invalid size for shrinking BitRange. New size conflicts with real capacity of bit array.");
			}
			else
			{
				auto realSize = (size < 8) ? 1 : cpl2(size) >> 3;
				_bits = _bits[0..realSize];
				_capacity = size;
			}
		}
	}
	
	string toString()
	{
		string bits;
		
		foreach (i; 0.._capacity)
		{
			bits ~= (opIndex(i) == 0 ? "0" : "1");
		}
	
		return bits;
	}
}
