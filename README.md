# KronosExternal
Kronos module to declare inputs and buffers for external code (wrappers)

## Usage

- To declare a parameter, use the `Param` package:

    ```
    Import [vitreo12/KronosExternal 0.1]
    Use Param

    Main() {
        ; Different ways to declare a parameter. p3 also implements min / max ranges.
        p1 = Param:New("p1" #1)
        p2 = Param("p2" #1)
        p3 = Param("p3" #1 #0 #1)

        ... your code ...
    }
    ```

- To declare a `Buffer`, use the `Buffer` package:

    ```
    Import [vitreo12/KronosExternal 0.1]
    Use Buffer

    Main() {
        ; Different ways to declare a Buffer. b2 limits the size to 48000 samples.
        ; If not specified, the default is 480000 (10 seconds of mono at 48khz).
        b1 = Buffer:New("b1")
        b2 = Buffer("b2" #48000)

        ... your code ...
    }
    ```
