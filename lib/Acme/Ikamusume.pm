package Acme::Ikamusume;
use 5.008001;
use strict;
use warnings;
our $VERSION = '0.08';
use Carp;
use Text::MeCab;
use Encode qw/find_encoding/;
use Class::Trigger;
use File::ShareDir;

my $encoding = Encode::find_encoding( Text::MeCab::ENCODING );

use Acme::Ikamusume::MAParser;
use Acme::Ikamusume::Rule;

sub new {
    my $self = bless {}, shift;
    Acme::Ikamusume::Rule->set_rules($self);
    $self;
}

sub geso {
    my ($self, $input) = @_;
    return "" unless defined $input;
    $self = $self->new unless ref $self;
    
    my $parser = Acme::Ikamusume::MAParser->new({
        userdic => File::ShareDir::dist_file('Acme-Ikamusume', 'ika.dic'),
    });
    
    my @result;
    for my $text (split /(\s+)/, $input) {
        if ($text =~ /\s/) {
            push @result, $text;
            next;
        }
        
        my @words;
        foreach (
            my $node = $parser->parse($text);
            $node;
            $node = $node->next
        ) {
            next if $node->stat =~ /[23]/; # skip MECAB_(BOS|EOS)_NODE
            push @words, $encoding->decode($node->surface);
            
            $self->call_trigger('node' => ($node, \@words));
            $self->call_trigger('node.has_extra' => ($node, \@words)) if $node->features->{extra};
            $self->call_trigger('node.readable'  => ($node, \@words)) if $node->features->{yomi};
        }
        
        push @result, @words;
    }

    join "", @result;
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::Ikamusume - The invader comes from the bottom of the sea!

=head1 SYNOPSIS

  use Acme::Ikamusume;
  use utf8;
  Acme::Ikamusume->geso('イカ娘です。あなたもperlで侵略しませんか？');
  # => イカ娘でゲソ。お主もperlで侵略しなイカ？

=head1 DESCRIPTION

Acme::Ikamusume module converts text to Ikamusume like talk.
Ikamusume, meaning "Squid-Girl", she is a cute Japanese comic/manga
character (L<http://www.ika-musume.com/>).

Try this module here: L<http://ika.koneta.org/>. enjoy!

=head1 METHODS

=over 4

=item Acme::Ikamusume->geso( $text )

About how the conversion, please see L<Acme::Ikamusume::Rule> and t/01_geso.t.

=back

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
