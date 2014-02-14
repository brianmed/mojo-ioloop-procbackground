package Mojo::IOLoop::ProcBackground;

use Mojo::Base 'Mojo::EventEmitter';

use Proc::Background;

# 
# Thanks to Mojo::IOLoop::ReadWriteFork and Mojo::IOLoop::ForkCall 
#

use constant DEBUG => $ENV{MOJO_PROCBACKGROUND_DEBUG} || 0;

our $VERSION = '0.02';

=head1 NAME

Mojo::IOLoop::ProcBackground - IOLoop interface to Proc::Background

=head1 VERSION

0.01

=head1 DESCRIPTION

This is an IOLoop interface to Proc::Background.

From Proc::Background:

    This is a generic interface for placing processes in the background on both Unix and
    Win32 platforms.  This module lets you start, kill, wait on, retrieve exit values, and
    see if background processes still exist.


=head1 SYNOPSIS

    use Mojolicious::Lite;

    use Mojo::IOLoop::ProcBackground;

    use File::Temp;
    use Proc::Background;
    use Fcntl qw(SEEK_SET SEEK_END);
    use IO::Handle;

    our $script = pop @ARGV or die("Please pass in a script.\n");

    any '/run' => sub {
            my $self = shift;

            Mojo::IOLoop->stream($self->tx->connection)->timeout(30);
            $self->render_later;

            $self->on(finish => sub { 
                $self->app->log->debug("Finished");
            });

            $self->res->code(200);
            $self->res->headers->content_type('text/html');
            $self->write_chunk("<html><body><div id=stuff>Starting...<br></div>");

            my $tmp = File::Temp->new(UNLINK => 0, SUFFIX => '.txt');
            my $output = $self->stash->{_output} = $tmp->filename;
            my $command = qq($^X $script $output);

            my $proc = $self->stash->{_proc} = Mojo::IOLoop::ProcBackground->new;

            $proc->on(alive => sub {
                my ($proc) = @_;

                my $told = $self->stash->{_told} // 0;
                my $output = $self->stash->{_output};

                open(my $fh, "<", $output);
                if (fileno($fh)) {
                    seek($fh, 0, SEEK_END);
                    my $end = tell($fh);

                    if ($told != $end) {
                        seek($fh, $told, SEEK_SET);
                        read($fh, my $buf, 1024);
                        $self->stash->{_told} = tell($fh);
                        chomp($buf);
                        $self->write_chunk(qq(<script>document.getElementById("stuff").innerHTML += "$buf<br>";</script>\n));
                    }
                }
            });

            $proc->on(dead => sub {
                my ($proc) = @_;

                $self->app->log->debug("Done");
                $self->write_chunk("Done</body></html>");
                $self->finish;
            });

            $proc->run($command);
    };

    push(@ARGV, 'daemon', '-l', 'http://*:5555') unless @ARGV;

    app->log->level("debug");
    app->secrets(["I Knos# you!!"]);
    app->start;

=head2 SEE ALSO

=over

=item L<Mojo::IOLoop::ReadWriteFork>

=item L<Mojo::IOLoop::ForkCall>

=back

=cut

has recurring => undef;
has proc => undef;

sub run {
    my $self = shift;
    my $command = shift;

    my $proc = Proc::Background->new(ref($command) ? @{ $command } : $command);
    $self->proc($proc);

    my $recurring = Mojo::IOLoop->recurring(0.05 => sub {
        my $reactor = shift;

        if ($self->proc->alive) {
            $self->emit_safe("alive");
        }
        else {
            Mojo::IOLoop->remove($self->recurring);

            $self->emit_safe("dead");
        }
    });

    $self->recurring($recurring);
}

1;
