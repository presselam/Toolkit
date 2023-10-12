import inspect

from utilities import quick

def printDict(thing, ts=0):
    pad = ''.join([' ']*(ts*2))

    wide = 0
    for key in thing:
        if len(key) > wide:
            wide = len(key)

    retval = 'dict('+ str(hex(id(thing))) + '){ <' + str(len(thing)) + " keys>\n"
    for key in thing:
        retval = retval + pad + '  ' + key.ljust(wide) + " => "
        retval = retval + walker(thing[key], ts+1)
        retval = retval + "\n"

    retval = retval + pad + "}"

    return retval

def printBool(thing, ts=0):
    return 'True' if thing else 'False'

def printString(thing, ts=0):
    return str(thing)

def printObject(thing):
    print("OBJECT=" + walker(thing,1) + ';')

def printList(thing, ts=0):
    pad = ''.join([' ']*(ts*2))

    retval = 'list('+str(hex(id(thing)))+')[ <' + str(len(thing)) + " elements>\n"
    for item in thing:
        retval = retval + pad + '  '
        retval = retval + walker(item, ts+1)
        retval = retval + ",\n"

    retval = retval + pad + "]"

    return retval

def inspectClass(thing, ts=0):
    pad = ''.join([' ']*(ts*2))

    members = inspect.getmembers(thing)
#    quick(*members)

    wide = 0
    properties = []
    for prop in members:
        if inspect.isfunction(prop[1]):  continue
        quick(pad, prop[0], inspect.ismodule(prop[1]), inspect.isclass(prop[1]), inspect.ismethod(prop[1]), inspect.isfunction(prop[1]), inspect.isgeneratorfunction(prop[1]), inspect.isgenerator(prop[1]), inspect.iscoroutine(prop[1]), inspect.isawaitable(prop[1]), inspect.isasyncgenfunction(prop[1]), inspect.isasyncgen(prop[1]), inspect.istraceback(prop[1]), inspect.isframe(prop[1]), inspect.iscode(prop[1]), inspect.isbuiltin(prop[1]), inspect.isroutine(prop[1]), inspect.isabstract(prop[1]), inspect.ismethoddescriptor(prop[1]), inspect.isdatadescriptor(prop[1]), inspect.isgetsetdescriptor(prop[1]), inspect.ismemberdescriptor(prop[1]) )       

        if not inspect.ismethod(prop[1]):
            if len(prop[0]) > wide: wide = len(prop[0])
            properties.append(prop)

    retval = str(thing.__class__.__name__) + "{\n"
    for prop in properties:
#        retval = f"{retval}{pad}  {prop[0]:<{wide}} => {prop[1]}\n"
        retval = f"{retval}{pad}  {prop[0]:<{wide}} => " + walker(prop[1], ts+1) + "\n"

    retval = retval + "}"

    return retval

def walker(thing, ts=0):    
    dispatch = {
        dict : printDict,
        list : printList,
        bool : printBool,
        str  : printString,
        int  : printString,
        float : printString,
    }

    quick(thing, type(thing))
    if type(thing) in dispatch:
        return dispatch[type(thing)](thing,ts)
    
    return inspectClass(thing, ts)


