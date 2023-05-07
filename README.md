# KronosExternal
Kronos module to declare inputs and buffers for external code (wrappers)

## Usage

- To declare a parameter, use the `Param` package:

    ```
    Import [vitreo12/KronosExternal 1.0]

    Main() {
        ; Different ways to declare a parameter. p2 also implements min / max ranges.
        p1 = Param:New("p1" #1)
        p2 = Param:New("p2" #1 #0 #1)

        ... your code ...
    }
    ```

- To declare a `Buffer`, use the `Buffer` package:

    ```
    Import [vitreo12/KronosExternal 1.0]

    Main() {
        ; Different ways to declare a Buffer. b2 limits the maximum size to 48000 samples.
        ; If not specified, the default is 48000 * 30 (30 seconds of mono at 48khz).
        ; Note that a higher value does not impact performance or binary size, but just compilation times.
        b1 = Buffer:New("b1")
        b2 = Buffer:New("b2" #48000)

        ... your code ...
    }
    ```
