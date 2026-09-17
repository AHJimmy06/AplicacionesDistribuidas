using Microsoft.EntityFrameworkCore;
using ProgramacionDisrtibuidaC.Data;
using ProgramacionDisrtibuidaC.Interfaces;
using ProgramacionDisrtibuidaC.Models;

namespace ProgramacionDisrtibuidaC.Repositories
{
    public class ProductRepository : IProduct
    {
        private readonly AppDbContext _context;

        public ProductRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<List<Product>> GetAllAsync()
        {
            return await _context.Product
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<Product?> GetByIdAsync(int id)
        {
            return await _context.Product
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == id);
        }

        public async Task UpdateAsync(
            Product product,
            byte[] versions)
        {
            _context.Attach(product);

            _context.Entry(product)
                .Property(p => p.Name)
                .IsModified = true;

            _context.Entry(product)
                .Property(p => p.Price)
                .IsModified = true;

            _context.Entry(product)
                .Property(p => p.Stock)
                .IsModified = true;

            _context.Entry(product)
                .Property(p => p.Description)
                .IsModified = true;

            _context.Entry(product)
                .Property(p => p.ImageUrl)
                .IsModified = true;

            _context.Entry(product)
                .Property(p => p.IsActive)
                .IsModified = true;

            _context.Entry(product)
                .Property(p => p.Versions)
                .OriginalValue = versions;

            await _context.SaveChangesAsync();
        }
    }
}