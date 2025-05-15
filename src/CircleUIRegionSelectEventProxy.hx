package madden.event;
import dgui.math.Vector2;
import zinc.utils.MathUtil;
import zinc.data.Pair;
import zinc.publish.Publisher;
import dgui.math.Vector3;
import dgui.math.Quaternion;

@:enum
abstract StartingDirection(Int) to Int from Int
{
    var TOP_CLOCKWISE               = 1;
    var BOTTOM_CLOCKWISE            = 1 << 1;
    var TOP_ANITCLOCKWISE           = 1 | ANITCLOCKWISE;
    var BOTTOM_ANITCLOCKWISE        = (1 << 1) | ANITCLOCKWISE;
    var ANITCLOCKWISE               = 4; //unusable
}

@:enum
abstract StartingMode(Int) to Int from Int
{
    var SPACE_FIRST               = 1;  //O| |     | |     |
    var CHUNK_FIRST               = 2;  //O|     | |     | |
    var SPACE_FIRST_CENTER        = 3;  // |O|     | |     |
    var CHUNK_FIRST_CENTER        = 4;  // |  O  | |     | |
}

@:enum
abstract EdgeCase(Int) to Int from Int
{
    var NONE                     = 0;
    var STARTING_POINT           = 1;
    var ENDING_POINT             = 2;
    var BOTH                     = 3;
}

class CircleUIRegionSelectEventProxy
{
    //==========================================================================================
    //  Properties
    //==========================================================================================
    public var pieces(get,set):Int;
    public var space(get,set):Float;
    public var origin(get,set):Vector2;
    public var minRadius(get,set):Float;
    public var maxRadius(get,set):Float;
    public var beginAngle(get,set):Float;
    public var endAngle(get,set):Float;
    public var startDirection(get,set):StartingDirection;
    public var startMode(get,set):StartingMode;
    public var filpY(get,set):Bool;
    public var filpDirection(get,set):Bool;
    public var edgeCase(get,set):EdgeCase;
    // param 1 is current index, param 2 is moving or not
    public var onIndexChanged(get,never):Publisher<Int->Bool->Void>;
    public var dynamicOrigin:Bool = false;


    //==========================================================================================
    //  Fields
    //==========================================================================================
    private var _pieces:Int = 5;
    private var _space:Float = 5.0;
    private var _origin:Vector2 = new Vector2(0.0, 0.0);
    private var _minRadius:Float = 10.0;
    private var _maxRadius:Float = 100.0;
    private var _beginAngle:Float = 0.0;
    private var _endAngle:Float = 360.0;
    private var _startDirection:StartingDirection = StartingDirection.TOP_CLOCKWISE;
    private var _startMode:StartingMode = StartingMode.SPACE_FIRST_CENTER;
    private var _filpY:Bool = false;
    private var _filpDirection:Bool = false;
    private var _edgeCase:EdgeCase = EdgeCase.STARTING_POINT;
    private var _onIndexChanged:Publisher<Int->Bool->Void>;

    private var _piecesData:Array<Pair<Float,Float>>;
    private var _initalized:Bool = false;
    private var _currentIndex:Int = -1;

    function get_pieces():Int
    {
        return _pieces;
    }

    function set_pieces(value:Int):Int
    {
        if(value != _pieces)
        {
            _pieces = value;
            _checkUpdatePiecesData();
        }
        return _pieces;
    }

    function get_space():Float
    {
        return _space;
    }

    function set_space(value:Float):Float
    {
        if(!MathUtil.withinThreshold(value,_space, 0.01))
        {
            _space = value;
            _checkUpdatePiecesData();
        }
        return _space;
    }

    function get_origin():Vector2
    {
        return _origin;
    }

    function set_origin(value:Vector2):Vector2
    {
        return this._origin = value;
    }

    function get_minRadius():Float
    {
        return _minRadius;
    }

    function set_minRadius(value:Float):Float
    {
        return this._minRadius = value;
    }

    function get_maxRadius():Float
    {
        return _maxRadius;
    }

    function set_maxRadius(value:Float):Float
    {
        return this._maxRadius = value;
    }

    function get_beginAngle():Float
    {
        return _beginAngle;
    }

    function set_beginAngle(value:Float):Float
    {
        if(!MathUtil.withinThreshold(value,_beginAngle, 0.01))
        {
            _beginAngle = value;
            _checkUpdatePiecesData();
        }
        return _beginAngle;
    }

    function get_endAngle():Float
    {
        return _endAngle;
    }

    function set_endAngle(value:Float):Float
    {
        if(!MathUtil.withinThreshold(value,_endAngle, 0.01))
        {
            _endAngle = value;
            _checkUpdatePiecesData();
        }
        return _endAngle;
    }

    function get_startDirection():StartingDirection
    {
        return _startDirection;
    }

    function set_startDirection(value:StartingDirection):StartingDirection
    {
        if(value != _startDirection)
        {
            _startDirection = value;
            _checkUpdatePiecesData();
        }
        return _startDirection;
    }

    function get_startMode():StartingMode
    {
        return _startMode;
    }

    function set_startMode(value:StartingMode):StartingMode
    {
        if(value != _startMode)
        {
            _startMode = value;
            _checkUpdatePiecesData();
        }
        return _startMode;
    }

    function get_filpY():Bool
    {
        return _filpY;
    }

    function set_filpY(value:Bool):Bool
    {
        return this._filpY = value;
    }

    function get_filpDirection():Bool
    {
        return _filpDirection;
    }

    function set_filpDirection(value:Bool):Bool
    {
        return this._filpDirection = value;
    }

    function get_edgeCase():EdgeCase
    {
        return _edgeCase;
    }

    function set_edgeCase(value:EdgeCase):EdgeCase
    {
        return this._edgeCase = value;
    }

    function get_onIndexChanged():Publisher<Int->Bool->Void>
    {
        return _onIndexChanged;
    }

    private function _calcSpaceAngle(i:Int):Float
    {
        if (_startMode == StartingMode.SPACE_FIRST_CENTER && i == 0)
            return _space * 0.5;
        return _space;
    }


    private function _calcBeginAngle(stepAngle:Float):Float
    {
        if(_startMode == StartingMode.CHUNK_FIRST_CENTER)
            return _beginAngle - stepAngle;
        return _beginAngle;
    }

    private function _isSpaceFirst():Bool
    {
        return _startMode == StartingMode.SPACE_FIRST || _startMode == StartingMode.SPACE_FIRST_CENTER;
    }

    private function _updatePiecesData():Void
    {
        if(_piecesData == null)
            _piecesData = new Array<Pair<Float,Float>>();
        else
            _piecesData.resize(0);

        var stepAngle:Float = ((_endAngle - _beginAngle) / _pieces) - _space;
        var beginAngle:Float = _calcBeginAngle(stepAngle);


        for (i in 0..._pieces)
        {
            if(_isSpaceFirst())
                beginAngle += _calcSpaceAngle(i);
            _piecesData.push(new Pair<Float,Float>(beginAngle, beginAngle + stepAngle));
            beginAngle = beginAngle + stepAngle;
            if(!_isSpaceFirst())
                beginAngle += _calcSpaceAngle(i);
        }

    }

    private function _getY(y:Float):Float
    {
        if(_filpY)
            return y * -1.0;
        return y;
    }

    private function _getStartingVectorNormalized():Vector2
    {
        if(_startDirection == StartingDirection.TOP_CLOCKWISE)
            return new Vector2(0.0, _getY(1.0) );
        else if(_startDirection == StartingDirection.BOTTOM_CLOCKWISE)
            return new Vector2(0.0, _getY(-1.0) );
        else if(_startDirection == StartingDirection.TOP_ANITCLOCKWISE)
            return new Vector2(0.0, _getY(1.0) );
        else if(_startDirection == StartingDirection.BOTTOM_ANITCLOCKWISE)
            return new Vector2(0.0, _getY(-1.0) );
        return new Vector2(0.0, _getY(1.0) );
    }

    private function _getCurrentVector(pos:Vector2):Vector2
    {
        return pos - _origin;
    }

    private function _isClockwise():Bool
    {
        return (_startDirection & StartingDirection.ANITCLOCKWISE) == 0;
    }

    private function _calcAngle(currentVec:Vector2):Float
    {
        var startVec:Vector2 = _getStartingVectorNormalized();
        var currentVecNor:Vector2 = currentVec.normalized;
        var isClockwise:Bool = _isClockwise();

        var dot = Vector2.Dot(startVec,currentVecNor);
        var cross = startVec.x * currentVecNor.y - startVec.y * currentVecNor.x;

        var angle = Math.acos(dot);

        var actualIsClockwise = cross < 0;
        if(_filpDirection)
        {
            actualIsClockwise = !actualIsClockwise;
        }

        if (isClockwise != actualIsClockwise) {
            angle = 2 * Math.PI - angle;
        }

        return MathUtil.degreesFromRadians(angle);
    }

    private function _checkRadius(pos:Vector2):Bool
    {
        var radius:Float = (pos - _origin).magnitude;
        return radius > _minRadius && radius <= _maxRadius;
    }

    private function _isInRange(angle:Float,min:Float,max:Float):Bool
    {
        switch (_edgeCase)
        {
            case EdgeCase.NONE:
                return angle > min && angle < max;
            case EdgeCase.STARTING_POINT:
                return angle >= min && angle < max;
            case EdgeCase.ENDING_POINT:
                return angle > min && angle <= max;
            case EdgeCase.BOTH:
                return angle >= min && angle <= max;
        }
        return false;
    }

    public function checkInRegion(pos:Vector2):Int
    {
        if(_initalized && _checkRadius(pos))
        {
            var angle:Float = _calcAngle(_getCurrentVector(pos));
            var index:Int = 0;
            for (piece in _piecesData)
            {
                if(_isInRange(angle, piece.left, piece.right))
                {
                    return index;
                }
                ++index;
            }
        }
        return -1;
    }

    private function _checkUpdatePiecesData():Void
    {
        if(_initalized)
        {
            _updatePiecesData();
        }
    }

    public function init():Void
    {
        _updatePiecesData();
        _onIndexChanged = Publisher.acquire(_onIndexChanged);
        _initalized = true;
    }

    public function dispose():Void
    {
        _onIndexChanged = Publisher.release(_onIndexChanged);
        _initalized = false;
    }

    private function _setCurrentIndex(value:Int,moving:Bool):Int
    {
        if(_initalized && _currentIndex != value)
        {
            _currentIndex = value;
            _publishIndexChanged(value,moving);
        }else
        if(!moving)
        {
            _publishIndexChanged(value,moving);
        }
        return _currentIndex;
    }

    private function _publishIndexChanged(index:Int,moving:Bool):Void
    {
        if(onIndexChanged != null)
        {
            onIndexChanged.publish(index, moving);
        }
    }

    public function press(x:Float,y:Float):Void
    {
        if(dynamicOrigin)
        {
            _origin = new Vector2(x,y);
        }else{
            _setCurrentIndex(checkInRegion(new Vector2(x,y)),true);
        }
    }

    public function move(x:Float,y:Float):Void
    {
        _setCurrentIndex(checkInRegion(new Vector2(x,y)),true);
    }

    public function release(x:Float,y:Float):Void
    {
        _setCurrentIndex(checkInRegion(new Vector2(x,y)),false);
    }

    public function getRegionPosAndRotate(origin:Vector2,radius:Float):Array<Vector3>
    {
        if(!_initalized)
            return null;
        var arr:Array<Vector3> = new Array<Vector3>();
        arr.resize(_piecesData.length);

        var startVec:Vector2 = _getStartingVectorNormalized();
        for (i in 0..._piecesData.length)
        {
            var piece:Pair<Float,Float> = _piecesData[i];
            var angle:Float = piece.left + ((piece.right - piece.left) * 0.5);

            var point:Vector2 = startVec * radius;
            var result:Vector3 = Quaternion.AngleAxis(angle, new Vector3(0,0,1)) * new Vector3(point.x, point.y, 0);
            var result = result + new Vector3(origin.x, origin.y, angle);
            arr[i] = result;
        }
        return arr;
    }

    public function new()
    {
        _currentIndex = -1;
    }

}
