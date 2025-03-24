#Requires AutoHotkey v2.0

view_array(arr) {
    str := '`nArray contents:'
    for index, value in arr
        str .= '`nIndex ' index ':' value
    return str
}

MsgBox view_array(A_Args), A_ScriptName