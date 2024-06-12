%PARSEMSGPACK parses a msgpack byte buffer into Matlab data structures
% PARSEMSGPACK(BYTES)
%    reads BYTES as msgpack data, and creates Matlab data structures
%    from it. The number of bytes consumed by the parsemsgpack call 
%    is returned in the variable IDX.
%    - strings are converted to strings
%    - numbers are converted to appropriate numeric values
%    - true, false are converted to logical 1, 0
%    - nil is converted to []
%    - arrays are converted to cell arrays
%    - maps are converted to containers.Map

% (c) 2016 Bastian Bechtold
% voluntary contributions made by Christopher Nadler (cnadler86)
% This code is licensed under the BSD 3-clause license

function [obj, idx] = parsemsgpack(bytes)
    [obj, idx] = parse(uint8(bytes(:)), 1);
end

function [obj, idx] = parse(bytes, idx)
    % masks:
    b10000000 = uint8(128);
    b11100000 = uint8(224);
    b00011111 = uint8(31);
    b11110000 = uint8(240);
    b00001111 = uint8(15);
    % values:
    b00000000 = uint8(0);
    b10010000 = uint8(144);
    b10100000 = uint8(160);

    currentbyte = bytes(idx);

    if bitand(b10000000, currentbyte) == b00000000
        % decode positive fixint
        obj = int8(currentbyte);   %if you need more performance you could try to use uint8 instead of int here
        idx = idx + 1;
        return
    elseif bitand(b11100000, currentbyte) == b11100000
        % decode negative fixint
        obj = typecast(currentbyte, 'int8');
        idx = idx + 1;
        return
    elseif bitand(b11110000, currentbyte) == b10000000
        % decode fixmap
        len = double(bitand(b00001111, currentbyte));
        [obj, idx] = parsemap(len, bytes, idx+1);
        return
    elseif bitand(b11110000, currentbyte) == b10010000
        % decode fixarray
        len = double(bitand(b00001111, currentbyte));
        [obj, idx] = parsearray(len, bytes, idx+1);
        return
    elseif bitand(b11100000, currentbyte) == b10100000
        % decode fixstr
        len = double(bitand(b00011111, currentbyte));
        [obj, idx] = parsestring(len, bytes, idx + 1);
        return
    end

    switch currentbyte
        case uint8(192) % nil
            obj = [];
            idx = idx+1;
      % case uint8(193 % unused
        case uint8(194) % false
            obj = false;
            idx = idx+1;
        case uint8(195) % true
            obj = true;
            idx = idx+1;
        case uint8(196) % bin8
            len = double(bytes(idx+1));
            [obj, idx] = parsebytes(len, bytes, idx+2);
        case uint8(197) % bin16
            len = double(bytes2scalar(bytes(idx+1:idx+2), 'uint16'));
            [obj, idx] = parsebytes(len, bytes, idx+3);
        case uint8(198) % bin32
            len = double(bytes2scalar(bytes(idx+1:idx+4), 'uint32'));
            [obj, idx] = parsebytes(len, bytes, idx+5);
        case uint8(199) % ext8
            len = double(bytes(idx+1));
            [obj, idx] = parseext(len, bytes, idx+2);
        case uint8(200) % ext16
            len = double(bytes2scalar(bytes(idx+1:idx+2), 'uint16'));
            [obj, idx] = parseext(len, bytes, idx+3);
        case uint8(201) % ext32
            len = double(bytes2scalar(bytes(idx+1:idx+4), 'uint32'));
            [obj, idx] = parseext(len, bytes, idx+5);
        case uint8(202) % float32
            obj = bytes2scalar(bytes(idx+1:idx+4), 'single');
            idx = idx+5;
        case uint8(203) % float64
            obj = bytes2scalar(bytes(idx+1:idx+8), 'double');
            idx = idx+9;
        case uint8(204) % uint8
            obj = bytes(idx+1);
            idx = idx+2;
        case uint8(205) % uint16
            obj = bytes2scalar(bytes(idx+1:idx+2), 'uint16');
            idx = idx+3;
        case uint8(206) % uint32
            obj = bytes2scalar(bytes(idx+1:idx+4), 'uint32');
            idx = idx+5;
        case uint8(207) % uint64
            obj = bytes2scalar(bytes(idx+1:idx+8), 'uint64');
            idx = idx+9;
        case uint8(208) % int8
            obj = bytes2scalar(bytes(idx+1), 'int8');
            idx = idx+2;
        case uint8(209) % int16
            obj = bytes2scalar(bytes(idx+1:idx+2), 'int16');
            idx = idx+3;
        case uint8(210) % int32
            obj = bytes2scalar(bytes(idx+1:idx+4), 'int32');
            idx = idx+5;
        case uint8(211) % int64
            obj = bytes2scalar(bytes(idx+1:idx+8), 'int64');
            idx = idx+9;
        case uint8(212) % fixext1
            [obj, idx] = parseext(1, bytes, idx+1);
        case uint8(213) % fixext2
            [obj, idx] = parseext(2, bytes, idx+1);
        case uint8(214) % fixext4
            [obj, idx] = parseext(4, bytes, idx+1);
        case uint8(215) % fixext8
            [obj, idx] = parseext(8, bytes, idx+1);
        case uint8(216) % fixext16
            [obj, idx] = parseext(16, bytes, idx+1);
        case uint8(217) % str8
            len = double(bytes(idx+1));
            [obj, idx] = parsestring(len, bytes, idx+2);
        case uint8(218) % str16
            len = double(bytes2scalar(bytes(idx+1:idx+2), 'uint16'));
            [obj, idx] = parsestring(len, bytes, idx+3);
        case uint8(219) % str32
            len = double(bytes2scalar(bytes(idx+1:idx+4), 'uint32'));
            [obj, idx] = parsestring(len, bytes, idx+5);
        case uint8(220) % array16
            len = double(bytes2scalar(bytes(idx+1:idx+2), 'uint16'));
            [obj, idx] = parsearray(len, bytes, idx+3);
        case uint8(221) % array32
            len = double(bytes2scalar(bytes(idx+1:idx+4), 'uint32'));
            [obj, idx] = parsearray(len, bytes, idx+5);
        case uint8(222) % map16
            len = double(bytes2scalar(bytes(idx+1:idx+2), 'uint16'));
            [obj, idx] = parsemap(len, bytes, idx+3);
        case uint8(223) % map32
            len = double(bytes2scalar(bytes(idx+1:idx+4), 'uint32'));
            [obj, idx] = parsemap(len, bytes, idx+5);
        otherwise
            error('transplant:parsemsgpack:unknowntype', ...
                  ['Unknown type "' dec2bin(currentbyte) '"']);
    end
end

function value = bytes2scalar(bytes, type)
    % reverse byte order to convert from little-endian to big-endian
    value = typecast(bytes(end:-1:1), type);
end

function [str, idx] = parsestring(len, bytes, idx)
    str = native2unicode(bytes(idx:idx+len-1)', 'utf-8');
    idx = idx + len;
end

function [out, idx] = parsebytes(len, bytes, idx)
    out = bytes(idx:idx+len-1);
    idx = idx + len;
end

function [out, idx] = parseext(len, bytes, idx)
    out.type = bytes(idx);
    out.data = bytes(idx+1:idx+len);
    idx = idx + len + 1;
end

function [out, idx] = parsearray(len, bytes, idx)
    % out = cell(1, len);
    % for n=1:len
    %     [out{n}, idx] = parse(bytes, idx);
    % end

    % In most of the cases this is faster than using a preallocated cell (approach above). Array cannot be preallocated because the datatype is defined by the first call of the for loop.
    % %Chosse how to manage arrays by commetinnig out/in.
    for n=1:len
        [out(n), idx] = parse(bytes, idx); %#ok<AGROW>: still better than using a cell and preallocating
    end
end

function [out, idx] = parsemap(len, bytes, idx)
    % out = containers.Map();
    % for n=1:len
    %     [key, idx] = parse(bytes, idx);
    %     [out(key), idx] = parse(bytes, idx);
    % end

    %Using struct in faster and more user friendly. 
    out = struct();
    for n=1:len
        [key, idx] = parse(bytes, idx);
        [out.(replaceMsgPackKey(key)), idx] = parse(bytes, idx);
    end
end

function ret = replaceMsgPackKey(num)
    %add specific key names in here dependent on your specific msgpack serialisation.
    %Always use uint8 in order to maintain performance.
    % Example:
        % switch num
        %     case uint8(17)
        %         ret = 'data';
        %     case uint8(18)
        %         ret = 'numOfElems';
        %     case uint8(19)
        %         ret = 'elemSz';
        %     case uint8(20)
        %         ret = 'endian';
        %     case uint8(21)
        %         ret = 'elemTypes';
        %     case uint8(16)
        %         ret = 'class';
        % end

    switch num
        otherwise
            ret = sprintf('Key%s',num);
    end
end