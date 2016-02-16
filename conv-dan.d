module main;

void main(string[] args)
{
    import std.stdio, std.conv;

    if (args.length < 3)
        return stderr.writeln("conv-dan count trial [f|t|s|y] [rank-proportion]");

    immutable
        count = args[1].to!size_t,
        trial = args[2].to!size_t;

    int[] pt = [6, 3, 0, 1];
    if (args.length == 4 || args.length == 8) switch (args[3])
    {
        case "f": break;                    // feng huang
        case "t": pt = [5, 2, 0, 1]; break; // te shang
        case "s": pt = [4, 1, 0, 1]; break; // shang ji
        case "y": pt = [3, 0, 0, 1]; break; // yi ban
        default: stderr.writeln("Wrong table specification. Default value f used."); break;
    }
    real[] pr = [1, 1, 1, 1];
    if (args.length == 7 || args.length == 8)
        foreach (i, ref elem; pr)
            elem = args[$-4+i].to!real;

    "%(%f\n%)".writefln(pr.probabilistic(pt, count, trial));
}

/** The probabilistic simulation for convergent dan.

Params:
    pr = the vector proportional to probability of each rank.
    pt = the point a player gains for each rank (except the last place), and the point a player loses for the last place per his/her current dan.
    count = the number of games per simulation.
    trial = the number of simulations.

Returns:
    The sorted array of convergent dans. length == trial.
    For tenhou.net setting, subtract 2 from each element of the result.

Complexity:
    O((pr.length * count + log(trial)) * trial) time and O(trial) space.
*/
auto probabilistic(T, P)(T[] pr, P[] pt, in size_t count, in size_t trial)
in
{
    import std.algorithm : all;
    assert (pr.length == pt.length);
    assert (pr.all!"0 < a");
    assert (pr.all!"0 <= a");
    assert (0 < pr[$-1]);
    assert (0 < pr[0]);
}
body
{
    import std.algorithm : sort;
    real[] ret;
    foreach (i; 0..trial)
        ret ~= simulate(pr, pt, count);
    sort(ret);
    return ret;
}

/** The probabilistic simulation for convergent dan.

Params:
    pr = the vector proportional to probability of each rank.
    pt = the point a player gains for each rank (except the last place), and the point a player loses for the last place per his/her current dan.
    count = the number of games per simulation.

Returns:
    The convergent dan of the simulation.
    For tenhou.net setting, subtract 2 from each element of the result.

Complexity:
    O(pr.length * count) time and O(1) space.
*/
auto simulate(T, P)(T[] pr, P[] pt, in size_t count)
{
    import std.random, std.conv;
    P pts = 0;
    size_t lasts;
    foreach (j; 0..count)
    {
        auto rank = pr.dice;
        if (rank + 1 == pr.length)
            lasts += 1;
        else
            pts += pt[rank];
    }
    return pts / (pt[$ - 1] * lasts.to!real);
}
