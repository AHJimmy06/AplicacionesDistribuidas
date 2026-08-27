using Microsoft.EntityFrameworkCore;
using ProgramacionDisrtibuidaC.Models;

namespace ProgramacionDisrtibuidaC.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(
            DbContextOptions<AppDbContext> options)
            : base(options)
        {
        }

        public DbSet<Product> Product { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Product>()
                .Property(product => product.Price)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Product>()
                .Property(product => product.Version)
                .HasDefaultValue(0)
                .IsConcurrencyToken();
        }
    }
}
