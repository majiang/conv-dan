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

import std.typecons;
alias Pair = Tuple!(real, real);

/** Binary search for fuzzy function.

The algorithm is quite similar to ordinary binary search except that
the search is terminated when the in condition is not met.
*/
Pair fuzzyBinarySearch(alias f)(in real l, in real fl, in real ff, in real r, in real fr)
in
{
    assert (l < r);
    assert (fl < ff);
    assert (ff < fr);
}
body
{
    immutable
        m = (l + r) / 2,
        fm = f(m);
    import std.stdio, std.experimental.logger;
    tracef("%f => %f", m, fm);
    stderr.flush;
    if (fm <= fl) return Pair(l, r-l);
    if (fr <= fm) return Pair(r, r-l);
    if (ff == fm) return Pair(m, r-l);
    if (ff < fm) return fuzzyBinarySearch!f(l, fl, ff, m, fm);
    if (fm < ff) return fuzzyBinarySearch!f(m, fm, ff, r, fr);
    assert (false);
}
///
unittest
{
    import std.stdio;
    auto pt = [6, 3, 0, 1];
    auto results = findTpl(
        pt,      // feng huang
        100,     // the number of games
        1000000, // the number of simulations
          50000, // 5% of trial
        13);
    foreach (result; results)
    {
        immutable
            lower = result[0],
            upper = result[1];
        stderr.writefln("top-per-last ratio: [%.15f .. %.15f]", lower, upper);
        stderr.writefln("convergent dan(+2; 5%%): [%.15f .. %.15f]", lower.pr.cd(pt), upper.pr.cd(pt));
    }
}

Pair[] findTpl(int[] pt, int games, int trial, int rank, real target)
{
    import std.stdio;
    stderr.writefln("pt=%s, count=%s, trial=%s, rank=%s, target=%.15f", pt, games, trial, rank, target);
    auto trs = [1-real.epsilon, 1, 1+real.epsilon];
    assert (trs[0] * target != trs[1] * target);
    assert (trs[2] * target != trs[1] * target);
    Pair[] ret;
    foreach (targetRatio; trs)
    {
        auto p = fuzzyBinarySearch!
        ((real m) => m.pr.quantile!"b < a"(pt, games, trial, rank))
        (0, 0, target * targetRatio, 2, real.infinity);
        immutable
            lower = p[0] - p[1]/2,
            upper = p[0] + p[1]/2;
        ret ~= Pair(lower, upper);
    }
    return ret;
}


/** Convergent dan for given rank distribution and points. */
auto cd(T, P)(T[] pr, P[] pt)
in
{
    assert (pr.length == pt.length);
}
body
{
    real gain = 0;
    foreach (i; 0..pr.length - 1)
        gain += pr[i] * pt[i];
    return gain / (pr[$-1] * pt[$-1]);
}

/** A vector of the probability of a player getting the ranks.

Params:
    tpl = top-per-last ratio.

Returns:
    A four-element arithmetic progression whose first element is tpl times the last element.
*/
auto pr(real tpl)
{
    return [tpl*3, tpl*2+1, tpl+2, 3];
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

/** The probabilistic simulation for convergent dan.

Params:
    pr = the vector proportional to probability of each rank.
    pt = the point a player gains for each rank (except the last place), and the point a player loses for the last place per his/her current dan.
    count = the number of games per simulation.
    trial = the number of simulations.
    rank = the indicator of the returned value.

Returns:
    The rank-th smallest (according to less, i.e., if less is "a < b", smallest, if less is "b < a", largest) value of convergent dans for trial-times simulations.
    For tenhou.net setting, subtract 2 from each element of the result.

Complexity:
    O((pr.length * count + log(rank)) * trial) time and O(rank) space.
*/
auto quantile(alias less="a<b", T, P)(T[] pr, P[] pt, in size_t count, in size_t trial, in size_t rank)
{
    import std.container;
    auto h = new real[rank].heapify!less(0);
    foreach (i; 0..trial)
        h.conditionalInsert(pr.simulate(pt, count));
    return h.front;
}
