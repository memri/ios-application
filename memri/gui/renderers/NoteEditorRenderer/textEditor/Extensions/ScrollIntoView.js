// Enable smooth scrolling on safari iOS
import "scroll-behavior-polyfill";

export function scrollIntoView(t) {
    if (typeof t != "object") return;

    if (t.getRangeAt) {
        // we have a Selection object
        if (t.rangeCount == 0) return;
        t = t.getRangeAt(0);
    }

    if (t.cloneRange) {
        // we have a Range object
        var r = t.cloneRange(); // do not modify the source range
        r.collapse(true); // collapse to start
        t = r.startContainer;
        // if start is an element, then startOffset is the child number
        // in which the range starts
        if (t.nodeType == 1) t = t.childNodes[r.startOffset];
    }

    // if t is not an element node, then we need to skip back until we find the
    // previous element with which we can call scrollIntoView()
    var o = t;
    while (o && o.nodeType != 1) o = o.previousSibling;
    t = o || t.parentNode;
    if (t)
        t.scrollIntoView({
            behavior: "smooth",
            block: "nearest",
        });
}