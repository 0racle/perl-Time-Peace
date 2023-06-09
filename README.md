NAME
====

Time::Peace - A potentially buggy datetime module

ABOUT
=====

Years ago I was doing work on an ancient RHEL box that had a version of Perl 5.6 installed with no `Time::Piece` module (which was added in the Perl stlib from - I believe - Perl 5.8).

I needed something for simple parsing and comparing dates, so I wrote `Time::Peace`.

I'm leaving it hear for prosperity, but I probably wouldn't recommend you use this over [Time::Piece](https://metacpan.org/pod/Time::Piece) from the stdlin, or Datetime[https://metacpan.org/pod/DateTime] from CPAN.
