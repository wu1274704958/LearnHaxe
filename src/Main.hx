import haxe.Exception;

class TokenParseCxt
{
    public var Begin:Int = -1;
    public var End:Int = -1;
    private var TmpEnd:Int = -1;
	private var Value:Float = Math.NaN;
	private var Pure:Bool = false;
    
    public function valid():Bool {
        return Begin >= 0 && End >= 0 && End >= Begin; 
    }
    public function tryParse(str:String):Null<Float> {
		 if(!Math.isNaN(Value))
            return Value;
        var s = subStr(str);
        var v = Std.parseFloat(s);
        if(Math.isNaN(v))
            return null;
		Value = v;
        return v;
    }
    public function subStr(str:String):String {
        return StringTools.trim(str.substr(Begin,End - Begin + 1));
    }
    public function new() {
        Begin = -1;
        End = -1;    
    }
	public static function fromValue(v:Float):TokenParseCxt {
		var res = new TokenParseCxt();
        res.Begin = -1;
        res.End = -1;    
		res.Value = v;
		return res;
    }
    public function begin(v:Int)
    {
        Begin = v;
        TmpEnd = v;
        Pure = true;
    }
    public function Append(c:Int) {
		if (!IsNumChar(c))
			Pure = false;
        TmpEnd +=1 ;
    }
	public function IsNumChar(c:Int):Bool
	{
		return (c >= 48 && c <= 57) || c == 46 || c ==  32;
	}
    public function end()
    {
        if(isBegin() && !isEnd())
        {
            End = TmpEnd;
            TmpEnd = -1;
        }
    }
    public function isBegin():Bool
    {
        return Begin > -1;
    }
    public function isEnd():Bool {
        return End > -1;
    }
	public function IsPure():Bool
	{
		return Pure;
	}
	public function size():Int
	{
		return End - Begin + 1;
	}
}

enum EAction{
    Ignore;
    Append;
    Begin;
    End;
}

class OpData{
    public var Op:Int;
    public var OpPos:Int;
    public function new(op:Int,pos:Int) {
        Op = op;
        OpPos = pos;
    }
}

class Main{

    static function main()
    {
        while(true)
        {
            var userInput = Sys.stdin().readLine();
            if(userInput == "exit")
                break;
            var v = 0.0;
            try {
                v = calc(StringTools.trim(userInput));
            }catch(e:haxe.Exception)
            {
                Sys.stdout().writeString('Parse failed msg = ${e.message}\n');
			    Sys.stdout().flush();
                continue;
            }
			Sys.stdout().writeString('${v}\n');
			Sys.stdout().flush();
        }
    }

    static function unwrap<T>(t:Null<T>):T {
        switch t 
        {
            case v : return v;
            case null : throw new Exception('Is Null');
        }
    }
    
    static function GetOpPriority(op:Int):Int {
        switch (op)
        {
            case 42|47 : return 1;
            case 43|45 : return 2; 
        }
        return -1;
    }
    static function AddAndBegin(parseList:Array<TokenParseCxt>,i:Int) {
        if(parseList.length > 0 && !parseList[parseList.length - 1].isEnd())
            parseList.pop();
        var v = new TokenParseCxt();
        v.begin(i);
        parseList.push(v);
    }
    static function TryEndLast(parseList:Array<TokenParseCxt>) {
        if(parseList.length > 0 && !parseList[parseList.length - 1].isEnd())
        {
            parseList[parseList.length - 1].end();
        }
    }
	static function combine(b:Int, e:Int, arr:Array<TokenParseCxt>): {t:TokenParseCxt,count:Int}
	{
        var s:Int = -1;
        var end:Int = -1;
		for(i in 0...arr.length)
        {
            if(s == -1 && arr[i].Begin > b)
                s = i;
            if(arr[i].End < e)
                end = i;
            if(arr[i].Begin > e)
                break;
        }
        if(s == end && s != -1)
            return { t: arr[s],count : 1};
        var res = new TokenParseCxt();
        res.Begin = arr[s].Begin;
        res.End = arr[end].End;
		return { t:res,count:end - s + 1};
	}
	static public function IsNumChar(c:Int):Bool
	{
		return (c >= 48 && c <= 57) || c == 46 ;
	}
	static function calcWithOp(a:Float,b:Float,op:Int):Float
	{
		switch(op)
		{
			case 42: return a * b;
			case 47: return a / b;
			case 43: return a + b;
			case 45: return a - b;
		}
		return 0.0;
	}
	static function calc(str:String):Float {
        var parseList:Array<TokenParseCxt> = new Array<TokenParseCxt>();
        var parenState:Int = 0;
        var op:Int = -1;
        var opPos:Array<OpData> = new Array<OpData>();
        var opPriority:Int = -1;
        var action:EAction = Ignore;
        var nextAction:EAction = Ignore;
        trace(str);
        for(i in 0...str.length)
        {
            var c = unwrap(str.charCodeAt(i));
            if(nextAction == Begin)
            {
                action = nextAction;
                nextAction = Ignore;
            }
            //trace('${c}');
            if(c == 40) // (
            {
                parenState += 1;
				if (parenState == 1)
				{
					action = Ignore;
					nextAction = Begin;
				}
            }else if(c == 41) // )
            {
                parenState -= 1;
                if(parenState == 0)
                {
                    action = End;   
                }
            }else if(parenState == 0 && (c == 42 || c == 47 || c == 43 || c == 45)) // *  / + - 
            {
                var priority = GetOpPriority(c);
                if(priority >= opPriority)
                {
                    if(priority > opPriority)
                        opPos.resize(0);
                    opPriority = priority;
                    opPos.push(new OpData(c,i));
                }
				if(action == Append)
					action = End;
            }
            if(action == Begin)
            {
                AddAndBegin(parseList,i);
                action = Append;
            }else if(action == End)
            {
                if (parseList.length == 0)
				{
					if (c != 45)
						throw new Exception("Parse failed 1");
					
				}else if(parseList[parseList.length - 1].isEnd())
                {
					throw new Exception("Parse failed 5");
				}
                parseList[parseList.length - 1].end();
                action = Ignore;
            }else if(action == Append)
            {
                if(parseList.length == 0 || parseList[parseList.length - 1].isEnd())
                    throw new Exception("Parse failed 2");
                parseList[parseList.length - 1].Append(c);
            }else if (IsNumChar(c)){
				AddAndBegin(parseList, i);
				action = Append;
			}
        }
        TryEndLast(parseList);
		if (opPos.length == 0)
		{
			if (parseList.length == 1 && parseList[0].isEnd() && parseList[0].size() < str.length)
			{
				if (parseList[0].IsPure())
					return parseList[0].tryParse(str);
				else
					return calc(parseList[0].subStr(str));
			}
			throw new Exception("Parse failed 3");
		}
		if (parseList.length < 2)
			throw new Exception("Parse failed 4");
		
		var mid:Int = -1;

        var b:Int = -1;
        var res:Float = 0.0;
        var count:Int = 0;
        op = 43;
        for(j in 0...opPos.length)
        {
            var val = null;
            var valToken:String = null;
            var token = null;
			var ret = combine(b, opPos[j].OpPos, parseList);
			token = ret.t;
			count = ret.count;
            if(count == 1 && token.IsPure())
                val = token.tryParse(str);
            else
                valToken = token.subStr(str);
            res = calcWithOp(res, val == null ? calc(valToken) : val, op);
			b = opPos[j].OpPos;
			op = opPos[j].Op;
        }
		
		var val = null;
        var valToken:String = null;
        var token = null;
		var ret = combine(b, str.length, parseList);
		token = ret.t;
		count = ret.count;
        if(count == 1 && token.IsPure())
            val = token.tryParse(str);
        else
            valToken = token.subStr(str);
        res = calcWithOp(res, val == null ? calc(valToken) : val, op);

        return res;
		 
		// for (j in 0...parseList.length)
		// {
		// 	if (parseList[j].Begin > opPos)
		// 	{
		// 		mid = j;
		// 		break;
		// 	}
		// }
		// if (mid < 0 || mid >= parseList.length)
		// 	throw new Exception("Parse failed 6");
		// var leftCount:Int = mid;
		// var rightCount:Int = parseList.length - mid;
		// var left = null;
		// var right = null;
		// var leftToken:String = null;
		// var rightToken:String = null;
		// if (mid == 0 && (op == 43 || op == 45))
		// 	left = 0.0;
		// //trace('${mid}  ${leftCount}  ${rightCount}');
		// if (leftCount == 1 && parseList[mid - 1].IsPure())
		// 	left = parseList[mid - 1].tryParse(str);
		// else
		// 	leftToken = StringTools.trim(str.substr(0,opPos));
		// if (rightCount == 1 && parseList[mid].IsPure())
		// 	right = parseList[mid].tryParse(str);
		// else
		// 	rightToken = StringTools.trim(str.substr(opPos + 1));
		
			
		// return calcWithOp(left == null ? calc(leftToken) : left , right == null ? calc(rightToken) : right , op);
	}
}