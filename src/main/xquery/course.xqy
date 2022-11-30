xquery version "1.0-ml";

declare option xdmp:output "method = html";

declare function local:saveCourse(
    $title as xs:string,
    $professor as xs:string?,
    $year as xs:string?,
    $fees as xs:string?,
    $stream as xs:string?
) as xs:string {
    let $id as xs:string := local:generateID()
    let $course as element(course) :=
        element book {
            attribute stream { $stream },
            attribute id { $id },
            element title { $title },
            element professor { $professor },
            element year { $year },
            element fees { $fees }
        }

    let $uri := '/coursestream/course-' || $id || '.xml'
    let $save := xdmp:document-insert($uri, $course)
    return
        $id
};

declare function local:generateID(
) as xs:string {
    let $hash :=
        xs:string(
            xdmp:hash64(
                fn:concat(
                    xs:string(xdmp:host()),
                    xs:string(fn:current-dateTime()),
                    xs:string(xdmp:random())
                )
            )
        )
    return
        local:padString($hash, 20, fn:false())
};

declare function local:padString(
    $string as xs:string,
    $length as xs:integer,
    $padLeft as xs:boolean
) as xs:string {
    if (fn:string-length($string) = $length) then (
        $string
    ) else if (fn:string-length($string) < $length) then (
        if ($padLeft) then (
            local:padString(fn:concat("0", $string), $length, $padLeft)
        ) else (
            local:padString(fn:concat($string, "0"), $length, $padLeft)
        )
    ) else (
        fn:substring($string, 1, $length)
    )
};

declare function local:sanitizeInput($chars as xs:string?) {
    fn:replace($chars,"[\]\[<>{}\\();%\+]","")
};

declare variable $id as xs:string? :=
    if (xdmp:get-request-method() eq "POST") then (
        let $title as xs:string? := local:sanitizeInput(xdmp:get-request-field("title"))
        let $author as xs:string? := local:sanitizeInput(xdmp:get-request-field("professor"))
        let $year as xs:string? := local:sanitizeInput(xdmp:get-request-field("year"))
        let $price as xs:string? := local:sanitizeInput(xdmp:get-request-field("fees"))
        let $category as xs:string? := local:sanitizeInput(xdmp:get-request-field("stream"))
        return
            local:saveCourse($title, $author, $year, $price, $category)
    ) else ();

(: build the html :)
xdmp:set-response-content-type("text/html"),
'<!DOCTYPE html>',
<html>
    <head>
        <title>Add Course</title>
    </head>
    <body>
        {
        if (fn:exists($id) and $id ne '') then (
            <div class="message">COurse Saved! ({$id})</div>
        ) else ()
        }
        <form name="add-course" action="add-course.xqy" method="post">
            <fieldset>
                <legend>Add Course</legend>
                <label for="title">Title</label> <input type="text" id="title" name="title"/>
                <label for="professor">Professor</label> <input type="text" id="professor" name="professor"/>
                <label for="year">Year</label> <input type="text" id="year" name="year"/>
                <label for="fees">Fees</label> <input type="text" id="fees" name="fees"/>
                <label for="stream">Category</label>
                <select name="stream" id="stream">
                    <option/>
                    {
                    for $c in ('CHILDREN','FICTION','NON-FICTION')
                    return
                        <option value="{$c}">{$c}</option>
                    }
                </select>
                <input type="submit" value="Save"/>
            </fieldset>
        </form>
    </body>
</html>