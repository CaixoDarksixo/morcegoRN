function [custo xord] = fit0(arg, Md)
% Com...
xord = sorti(bits2bytes(arg));
custo = Md(xord(1), xord(2)) + Md(xord(2), xord(3)) + Md(xord(3), xord(4)) + Md(xord(4), xord(5)) + Md(xord(5), xord(1));
