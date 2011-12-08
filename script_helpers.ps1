function assert( $test, $msg ) {
	if( -not $test ) {
		write-error "Assert Failed: " + $msg
		return
	}
}
